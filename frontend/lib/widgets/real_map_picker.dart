import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../core/app_theme.dart';

class RealMapPicker extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String? initialAddress;
  final Function(double lat, double lng, String address) onLocationChanged;
  final double height;

  const RealMapPicker({
    super.key,
    this.initialLat = 16.4322,
    this.initialLng = 102.8236,
    this.initialAddress,
    required this.onLocationChanged,
    this.height = 270,
  });

  @override
  State<RealMapPicker> createState() => _RealMapPickerState();
}

class _RealMapPickerState extends State<RealMapPicker> {
  late double _lat;
  late double _lng;
  int _zoom = 15;

  double _accumulatedDx = 0.0;
  double _accumulatedDy = 0.0;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLocating = false;
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _lat = widget.initialLat;
    _lng = widget.initialLng;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // แปลงพิกัด Lat/Lng เป็น Tile Coordinates
  static double _lngToTileX(double lng, int zoom) {
    return (lng + 180.0) / 360.0 * (1 << zoom);
  }

  static double _latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    return (1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * (1 << zoom);
  }

  static double _tileXToLng(double x, int zoom) {
    return x / (1 << zoom) * 360.0 - 180.0;
  }

  static double _tileYToLat(double y, int zoom) {
    final n = math.pi - 2.0 * math.pi * y / (1 << zoom);
    return 180.0 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  }

  // ค้นหาสถานที่จริงผ่าน OpenStreetMap Nominatim
  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&countrycodes=th&addressdetails=1',
      );
      final res = await http.get(uri, headers: {'User-Agent': 'WashQApp/1.0'});
      if (res.statusCode == 200) {
        final List list = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _searchResults = list.map((item) {
            return {
              'name': item['display_name'] ?? '',
              'lat': double.tryParse(item['lat']?.toString() ?? '') ?? _lat,
              'lng': double.tryParse(item['lon']?.toString() ?? '') ?? _lng,
            };
          }).toList();
        });
      }
    } catch (_) {
      // Ignore network errors in search
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // Reverse Geocoding: ดึงชื่อที่อยู่จริงจากพิกัด
  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1',
      );
      final res = await http.get(uri, headers: {'User-Agent': 'WashQApp/1.0'});
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        final address = data['display_name'] as String? ?? '';
        if (address.isNotEmpty && mounted) {
          widget.onLocationChanged(_lat, _lng, address);
        }
      }
    } catch (_) {
      // Fallback: notify with lat/lng
      widget.onLocationChanged(_lat, _lng, 'พิกัด $_lat, $_lng');
    }
  }

  // ดึงตำแหน่งพิกัด GPS ปัจจุบัน
  Future<void> _fetchGPS() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() => _isLocating = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      setState(() {
        _lat = double.parse(pos.latitude.toStringAsFixed(6));
        _lng = double.parse(pos.longitude.toStringAsFixed(6));
        _isLocating = false;
      });

      _reverseGeocode(_lat, _lng);
    } catch (_) {
      setState(() => _isLocating = false);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _accumulatedDx += details.delta.dx;
      _accumulatedDy += details.delta.dy;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    const tileSize = 256.0;
    final centerTileX = _lngToTileX(_lng, _zoom);
    final centerTileY = _latToTileY(_lat, _zoom);

    final newTileX = centerTileX - (_accumulatedDx / tileSize);
    final newTileY = centerTileY - (_accumulatedDy / tileSize);

    final newLng = _tileXToLng(newTileX, _zoom);
    final newLat = _tileYToLat(newTileY, _zoom);

    setState(() {
      _lng = double.parse(newLng.clamp(-180.0, 180.0).toStringAsFixed(6));
      _lat = double.parse(newLat.clamp(-85.0, 85.0).toStringAsFixed(6));
      _accumulatedDx = 0.0;
      _accumulatedDy = 0.0;
    });

    _reverseGeocode(_lat, _lng);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Search Bar for Real Places
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD6E4FF), width: 1.2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'พิมพ์ค้นหาสถานที่จริง (เช่น เซ็นทรัล ขอนแก่น, สยาม, ถ.มิตรภาพ)...',
              hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF0066FF), size: 20),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (val) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), () {
                _searchPlaces(val);
              });
            },
          ),
        ),

        // Search Results Dropdown
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final item = _searchResults[i];
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.location_on, color: Color(0xFF0066FF), size: 18),
                  title: Text(
                    item['name'] as String,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    final lat = item['lat'] as double;
                    final lng = item['lng'] as double;
                    final name = item['name'] as String;
                    setState(() {
                      _lat = lat;
                      _lng = lng;
                      _searchResults = [];
                      _searchController.text = name.split(',')[0];
                    });
                    widget.onLocationChanged(lat, lng, name);
                  },
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 10),

        // 2. Interactive Real Map Container
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCCE4FF), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Real Map Tiles Renderer with Pan Gesture
                Positioned.fill(
                  child: GestureDetector(
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildTileGrid(constraints.maxWidth, constraints.maxHeight);
                      },
                    ),
                  ),
                ),

                // Center Fixed Pin with Pulse Shadow
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2B5C),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8),
                          ],
                        ),
                        child: Text(
                          '${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF0066FF),
                        size: 44,
                        shadows: [
                          Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Floating Drag Hint Tag
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.touch_app, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text('ลากแผนที่เพื่อเลื่อนหมุด', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),

                // Zoom Controls & GPS Button (Bottom Right)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // GPS My Location
                      _buildMapCircleButton(
                        icon: _isLocating ? Icons.hourglass_top : Icons.my_location,
                        color: const Color(0xFF0066FF),
                        onTap: _isLocating ? null : _fetchGPS,
                        tooltip: 'ตำแหน่ง GPS ของฉัน',
                      ),
                      const SizedBox(height: 6),

                      // Zoom In
                      _buildMapCircleButton(
                        icon: Icons.add,
                        onTap: () {
                          if (_zoom < 18) setState(() => _zoom++);
                        },
                        tooltip: 'ซูมเข้า',
                      ),
                      const SizedBox(height: 4),

                      // Zoom Out
                      _buildMapCircleButton(
                        icon: Icons.remove,
                        onTap: () {
                          if (_zoom > 10) setState(() => _zoom--);
                        },
                        tooltip: 'ซูมออก',
                      ),
                    ],
                  ),
                ),

                // Map Attribution
                Positioned(
                  bottom: 6,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '© OpenStreetMap & CartoDB',
                      style: TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Renders 3x3 CartoDB Voyager map tiles centered smoothly
  Widget _buildTileGrid(double width, double height) {
    const tileSize = 256.0;

    final centerTileX = _lngToTileX(_lng, _zoom);
    final centerTileY = _latToTileY(_lat, _zoom);

    final pixelCenterX = (centerTileX - centerTileX.floor()) * tileSize - _accumulatedDx;
    final pixelCenterY = (centerTileY - centerTileY.floor()) * tileSize - _accumulatedDy;

    final startTileX = centerTileX.floor() - 1;
    final startTileY = centerTileY.floor() - 1;

    final tiles = <Widget>[];

    for (int dy = 0; dy <= 2; dy++) {
      for (int dx = 0; dx <= 2; dx++) {
        final tx = startTileX + dx;
        final ty = startTileY + dy;

        final maxTiles = 1 << _zoom;
        if (ty < 0 || ty >= maxTiles) continue;
        final normalizedTx = (tx % maxTiles + maxTiles) % maxTiles;

        final left = (width / 2.0) - pixelCenterX + ((dx - 1) * tileSize);
        final top = (height / 2.0) - pixelCenterY + ((dy - 1) * tileSize);

        final tileUrl = 'https://a.basemaps.cartocdn.com/rastertiles/voyager/$_zoom/$normalizedTx/$ty.png';

        tiles.add(
          Positioned(
            left: left,
            top: top,
            width: tileSize,
            height: tileSize,
            child: Image.network(
              tileUrl,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) {
                return Container(
                  color: const Color(0xFFF1F5F9),
                  child: const Center(
                    child: Icon(Icons.map_outlined, color: Color(0xFFCBD5E1), size: 30),
                  ),
                );
              },
            ),
          ),
        );
      }
    }

    return Stack(children: tiles);
  }

  Widget _buildMapCircleButton({
    required IconData icon,
    Color color = const Color(0xFF0F2B5C),
    required VoidCallback? onTap,
    String? tooltip,
  }) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
