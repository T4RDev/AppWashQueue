import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_provider.dart';
import '../models/vehicle_model.dart';
import '../core/app_theme.dart';
import '../core/app_snackbar.dart';

class MyCarsScreen extends StatefulWidget {
  const MyCarsScreen({super.key});

  @override
  State<MyCarsScreen> createState() => _MyCarsScreenState();
}

class _MyCarsScreenState extends State<MyCarsScreen> {
  String _selectedFilter = 'all'; // 'all', 'car', 'motorcycle'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VehicleProvider>(context, listen: false).fetchMyVehicles();
    });
  }

  void _showAddCarBottomSheet([VehicleModel? existingCar]) {
    final plateController = TextEditingController(text: existingCar?.plateNumber ?? '');
    final brandController = TextEditingController(text: existingCar?.brand ?? '');
    final modelController = TextEditingController(text: existingCar?.model ?? '');
    String selectedType = existingCar?.vehicleType ?? 'car';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingCar == null ? 'เพิ่มรถคันใหม่ 🚗' : 'แก้ไขข้อมูลรถ',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: plateController,
                    decoration: const InputDecoration(labelText: 'ป้ายทะเบียน (เช่น กข 1234 ขอนแก่น)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'ประเภทรถ'),
                    items: const [
                      DropdownMenuItem(value: 'car', child: Text('รถยนต์ (Sedan / Hatchback)')),
                      DropdownMenuItem(value: 'suv', child: Text('รถ SUV / กระบะ')),
                      DropdownMenuItem(value: 'motorcycle', child: Text('รถจักรยานยนต์')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: brandController,
                          decoration: const InputDecoration(labelText: 'ยี่ห้อ (เช่น Honda)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: modelController,
                          decoration: const InputDecoration(labelText: 'รุ่น (เช่น Civic)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (plateController.text.trim().isEmpty) {
                        AppSnackBar.showError(context, 'กรุณากรอกป้ายทะเบียน');
                        return;
                      }

                      final provider = Provider.of<VehicleProvider>(context, listen: false);
                      Navigator.pop(ctx);

                      bool success;
                      if (existingCar == null) {
                        success = await provider.addVehicle(
                          plateNumber: plateController.text.trim(),
                          vehicleType: selectedType,
                          brand: brandController.text.trim().isNotEmpty ? brandController.text.trim() : 'ทั่วไป',
                          model: modelController.text.trim().isNotEmpty ? modelController.text.trim() : 'มาตรฐาน',
                        );
                      } else {
                        success = await provider.updateVehicle(
                          id: existingCar.id,
                          plateNumber: plateController.text.trim(),
                          vehicleType: selectedType,
                          brand: brandController.text.trim().isNotEmpty ? brandController.text.trim() : 'ทั่วไป',
                          model: modelController.text.trim().isNotEmpty ? modelController.text.trim() : 'มาตรฐาน',
                        );
                      }

                      if (mounted && success) {
                        AppSnackBar.showSuccess(context, existingCar == null ? 'เพิ่มรถเรียบร้อยแล้ว' : 'แก้ไขข้อมูลรถเรียบร้อย');
                      }
                    },
                    child: Text(existingCar == null ? 'บันทึกข้อมูลรถ' : 'บันทึกการแก้ไข'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final allVehicles = vehicleProvider.vehicles;

    final filteredVehicles = allVehicles.where((v) {
      if (_selectedFilter == 'car') return v.vehicleType == 'car' || v.vehicleType == 'suv';
      if (_selectedFilter == 'motorcycle') return v.vehicleType == 'motorcycle';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => vehicleProvider.fetchMyVehicles(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header (Matches 2.5_My_Cars.png)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'รถของฉัน',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'จัดการรถที่ใช้จองคิว (${allVehicles.length} คัน)',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white, size: 24),
                        onPressed: () => _showAddCarBottomSheet(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Segment Tabs (Matches 2.5_My_Cars.png)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEF5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _buildSegmentTab('all', 'ทั้งหมด'),
                      _buildSegmentTab('car', 'รถยนต์'),
                      _buildSegmentTab('motorcycle', 'จักรยานยนต์'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                if (vehicleProvider.isLoading && allVehicles.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                else if (filteredVehicles.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.directions_car_outlined, size: 54, color: AppTheme.textMuted),
                          const SizedBox(height: 12),
                          const Text('ยังไม่มีข้อมูลรถที่บันทึกไว้', style: TextStyle(color: AppTheme.textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(minimumSize: const Size(140, 42)),
                            onPressed: () => _showAddCarBottomSheet(),
                            icon: const Icon(Icons.add),
                            label: const Text('เพิ่มรถคันแรก'),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Primary Car Card (Index 0) - Matches Dark Blue Card in 2.5_My_Cars.png
                  _buildPrimaryCarCard(filteredVehicles[0]),
                  const SizedBox(height: 14),

                  // Remaining Car Cards
                  ...filteredVehicles.skip(1).map((v) => _buildSecondaryCarCard(v)),

                  const SizedBox(height: 14),

                  // Dashed Add Car Button (Matches 2.5_My_Cars.png)
                  InkWell(
                    onTap: () => _showAddCarBottomSheet(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 1.5, style: BorderStyle.solid),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add, color: AppTheme.primaryColor, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '+ เพิ่มรถคันใหม่',
                            style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentTab(String key, String label) {
    final isSelected = _selectedFilter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryCarCard(VehicleModel v) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2B5C), Color(0xFF0066FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F2B5C).withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: ★ รถหลัก Badge & Edit/Delete buttons (Matches 2.5_My_Cars.png)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                    SizedBox(width: 4),
                    Text('รถหลัก', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary)),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                      onPressed: () => _showAddCarBottomSheet(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.delete_outline, color: Colors.white, size: 16),
                      onPressed: () => _confirmDeleteCar(v),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.plateNumber,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 2),
                  const Text('ขอนแก่น', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    '${v.brand} • ${v.model} • ${v.vehicleTypeThai}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const Icon(Icons.directions_car_filled, color: Colors.white24, size: 76),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryCarCard(VehicleModel v) {
    final isMotorcycle = v.vehicleType == 'motorcycle';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isMotorcycle ? const Color(0xFFE8F3FF) : const Color(0xFFE8F3FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(isMotorcycle ? Icons.two_wheeler : Icons.directions_car, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(v.plateNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Text(v.vehicleTypeThai, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${v.brand} • ${v.model}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
            onPressed: () => _showAddCarBottomSheet(v),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            onPressed: () => _confirmDeleteCar(v),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCar(VehicleModel v) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบรถทะเบียน ${v.plateNumber} ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, minimumSize: const Size(90, 38)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<VehicleProvider>(context, listen: false);
      final success = await provider.deleteVehicle(v.id);
      if (mounted && success) {
        AppSnackBar.showSuccess(context, 'ลบข้อมูลรถเรียบร้อยแล้ว');
      }
    }
  }
}
