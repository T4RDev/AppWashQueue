import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/api_constants.dart';
import '../../core/app_theme.dart';
import '../../core/app_snackbar.dart';

class OwnerSlotsTab extends StatefulWidget {
  const OwnerSlotsTab({super.key});

  @override
  State<OwnerSlotsTab> createState() => _OwnerSlotsTabState();
}

class _OwnerSlotsTabState extends State<OwnerSlotsTab> {
  final ApiService _api = ApiService();
  bool _isLoading = true;

  List<dynamic> _operatingDays = [];
  List<dynamic> _timeSlots = [];
  List<dynamic> _services = [];

  final List<Map<String, String>> _allDays = [
    {'key': 'monday', 'label': 'จ.'},
    {'key': 'tuesday', 'label': 'อ.'},
    {'key': 'wednesday', 'label': 'พ.'},
    {'key': 'thursday', 'label': 'พฤ.'},
    {'key': 'friday', 'label': 'ศ.'},
    {'key': 'saturday', 'label': 'ส.'},
    {'key': 'sunday', 'label': 'อา.'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final daysRes = await _api.get(ApiConstants.ownerOperatingDays);
      if (daysRes.success && daysRes.data != null) {
        _operatingDays = daysRes.data is List ? daysRes.data : [];
      }

      final slotsRes = await _api.get(ApiConstants.ownerTimeSlots);
      if (slotsRes.success && slotsRes.data != null) {
        _timeSlots = slotsRes.data is List ? slotsRes.data : [];
      }

      final servicesRes = await _api.get(ApiConstants.ownerServices);
      if (servicesRes.success && servicesRes.data != null) {
        _services = servicesRes.data is List ? servicesRes.data : [];
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  bool _isDayActive(String dayKey) {
    final found = _operatingDays.firstWhere(
      (d) => d['day_of_week'] == dayKey,
      orElse: () => null,
    );
    if (found == null) return false;
    return found['is_active'] == 1 || found['is_active'] == true;
  }

  Future<void> _toggleDay(String dayKey) async {
    final current = _isDayActive(dayKey);
    final updatedDays = _allDays.map((d) {
      final k = d['key']!;
      final isActive = k == dayKey ? !current : _isDayActive(k);
      return {'day_of_week': k, 'is_active': isActive};
    }).toList();

    final res = await _api.put(
      ApiConstants.ownerOperatingDays,
      body: {'days': updatedDays},
    );
    if (!mounted) return;
    if (res.success) {
      AppSnackBar.showSuccess(context, 'บันทึกวันเปิดทำการแล้ว');
      _fetchData();
    } else {
      AppSnackBar.showError(context, res.message);
    }
  }

  Future<void> _toggleSlot(int slotId, bool currentActive) async {
    final res = await _api.put(
      '${ApiConstants.ownerTimeSlots}/$slotId',
      body: {'is_active': !currentActive},
    );
    if (!mounted) return;
    if (res.success) {
      _fetchData();
    } else {
      AppSnackBar.showError(context, res.message);
    }
  }

  void _showAddTimeSlotDialog() {
    final startCtrl = TextEditingController(text: '08:00');
    final endCtrl = TextEditingController(text: '10:00');
    final capCtrl = TextEditingController(text: '3');
    String vehicleType = 'all';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('เพิ่มสล็อตเวลาให้บริการ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startCtrl,
                decoration: const InputDecoration(
                  labelText: 'เวลาเริ่ม (เช่น 08:00)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: endCtrl,
                decoration: const InputDecoration(
                  labelText: 'เวลาสิ้นสุด (เช่น 10:00)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: capCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ความจุคิวรับได้ (คัน)',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: vehicleType,
                decoration: const InputDecoration(labelText: 'ประเภทรถที่รับ'),
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('ทุกประเภท (All)'),
                  ),
                  DropdownMenuItem(value: 'car', child: Text('รถเก๋ง / Sedan')),
                  DropdownMenuItem(value: 'suv', child: Text('SUV / กระบะ')),
                  DropdownMenuItem(
                    value: 'motorcycle',
                    child: Text('มอเตอร์ไซค์'),
                  ),
                ],
                onChanged: (v) => setDState(() => vehicleType = v ?? 'all'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(90, 40)),
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await _api.post(
                  ApiConstants.ownerTimeSlots,
                  body: {
                    'start_time': startCtrl.text.trim(),
                    'end_time': endCtrl.text.trim(),
                    'capacity': int.tryParse(capCtrl.text) ?? 2,
                    'vehicle_type': vehicleType,
                  },
                );
                if (!mounted) return;
                if (res.success) {
                  AppSnackBar.showSuccess(context, 'เพิ่มสล็อตเวลาแล้ว');
                  _fetchData();
                } else {
                  AppSnackBar.showError(context, res.message);
                }
              },
              child: const Text('เพิ่ม'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddServiceDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String vehicleType = 'car';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('เพิ่มรายการบริการและราคา'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'ชื่อบริการ (เช่น ล้างอัดฉีด)',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: vehicleType,
                decoration: const InputDecoration(labelText: 'ประเภทรถ'),
                items: const [
                  DropdownMenuItem(value: 'car', child: Text('รถยนต์ (Car)')),
                  DropdownMenuItem(value: 'suv', child: Text('รถ SUV / กระบะ')),
                  DropdownMenuItem(
                    value: 'motorcycle',
                    child: Text('มอเตอร์ไซค์'),
                  ),
                ],
                onChanged: (v) => setDState(() => vehicleType = v ?? 'car'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ราคา (บาท)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(90, 40)),
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await _api.post(
                  ApiConstants.ownerServices,
                  body: {
                    'name': nameCtrl.text.trim(),
                    'vehicle_type': vehicleType,
                    'price': double.tryParse(priceCtrl.text) ?? 0,
                  },
                );
                if (!mounted) return;
                if (res.success) {
                  AppSnackBar.showSuccess(context, 'เพิ่มบริการเรียบร้อย');
                  _fetchData();
                } else {
                  AppSnackBar.showError(context, res.message);
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'วัน สล็อต & ราคา',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: วันให้บริการ (จ. อ. พ. พฤ. ศ. ส. อา.)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'วันให้บริการ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'แตะเพื่อเปิด/ปิด',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _allDays.map((d) {
                        final active = _isDayActive(d['key']!);
                        return GestureDetector(
                          onTap: () => _toggleDay(d['key']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                              border: Border.all(
                                color: active
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                              boxShadow: [
                                if (active)
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              d['label']!,
                              style: TextStyle(
                                color: active
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: สล็อตการให้บริการ (Matches 3.3_Days_Slots_Prices.png)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'สล็อตการให้บริการ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showAddTimeSlotDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('+ เพิ่มสล็อต'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_timeSlots.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'ยังไม่มีการกำหนดสล็อตเวลา',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    else
                      ..._timeSlots.map((s) => _buildSlotCard(s)),

                    const SizedBox(height: 24),

                    // Section 3: ราคาบริการ (Matches 3.3_Days_Slots_Prices.png)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ราคาบริการ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showAddServiceDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('+ เพิ่มบริการ'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildServicesTable(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSlotCard(dynamic s) {
    final slotId = s['id'] ?? 0;
    final startTime = (s['start_time'] ?? '08:00').toString().substring(0, 5);
    final endTime = (s['end_time'] ?? '10:00').toString().substring(0, 5);
    final isActive = s['is_active'] == 1 || s['is_active'] == true;
    final capacity = s['capacity'] ?? 2;
    final vehicleType = s['vehicle_type'] ?? 'all';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$startTime – $endTime',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'รับได้ $capacity คัน',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vehicleType == 'all' ? 'รับรถทุกประเภท' : vehicleType,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            activeThumbColor: const Color(0xFF00B96B),
            onChanged: (val) => _toggleSlot(slotId, isActive),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppTheme.error,
              size: 20,
            ),
            onPressed: () async {
              final res = await _api.delete(
                '${ApiConstants.ownerTimeSlots}/$slotId',
              );
              if (res.success) {
                _fetchData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTable() {
    if (_services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'ยังไม่มีรายการบริการ',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    'บริการ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ประเภท',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ราคา',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                SizedBox(width: 32),
              ],
            ),
          ),
          const Divider(height: 1),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _services.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final s = _services[i];
              final serviceId = s['id'] ?? 0;
              final name = s['name'] ?? '';
              final vt = s['vehicle_type'] ?? 'car';
              final price = (s['price'] ?? 0).toString();

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          vt == 'car'
                              ? 'รถยนต์'
                              : vt == 'suv'
                              ? 'SUV'
                              : 'มอไซค์',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '฿$price',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onPressed: () async {
                        final res = await _api.delete(
                          '${ApiConstants.ownerServices}/$serviceId',
                        );
                        if (res.success) _fetchData();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
