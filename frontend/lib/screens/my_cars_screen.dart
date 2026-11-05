import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_provider.dart';
import '../models/vehicle_model.dart';
import '../core/app_theme.dart';

class MyCarsScreen extends StatefulWidget {
  const MyCarsScreen({super.key});

  @override
  State<MyCarsScreen> createState() => _MyCarsScreenState();
}

class _MyCarsScreenState extends State<MyCarsScreen> {
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
                    decoration: const InputDecoration(labelText: 'ป้ายทะเบียน (เช่น 1กข-9999 กทม)'),
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
                          decoration: const InputDecoration(labelText: 'ยี่ห้อ (เช่น Honda, Toyota)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: modelController,
                          decoration: const InputDecoration(labelText: 'รุ่น (เช่น Civic, Fortuner)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (plateController.text.trim().isEmpty) return;

                      final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
                      bool success;

                      if (existingCar == null) {
                        success = await vehicleProvider.addVehicle(
                          plateNumber: plateController.text.trim(),
                          vehicleType: selectedType,
                          brand: brandController.text.trim().isEmpty ? '-' : brandController.text.trim(),
                          model: modelController.text.trim().isEmpty ? '-' : modelController.text.trim(),
                        );
                      } else {
                        success = await vehicleProvider.updateVehicle(
                          id: existingCar.id,
                          plateNumber: plateController.text.trim(),
                          vehicleType: selectedType,
                          brand: brandController.text.trim(),
                          model: modelController.text.trim(),
                        );
                      }

                      if (mounted) {
                        Navigator.pop(ctx);
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(vehicleProvider.errorMessage ?? 'ทำรายการไม่สำเร็จ'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
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

    return Scaffold(
      appBar: AppBar(title: const Text('รถส่วนตัวของฉัน 🚙')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('เพิ่มรถ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddCarBottomSheet(),
      ),
      body: RefreshIndicator(
        onRefresh: () async => vehicleProvider.fetchMyVehicles(),
        child: vehicleProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : vehicleProvider.vehicles.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car_outlined, size: 72, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'ยังไม่มีข้อมูลรถที่บันทึกไว้',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'แตะปุ่ม "เพิ่มรถ" ด้านล่างเพื่อเพิ่มข้อมูลรถคันแรกของคุณ',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: vehicleProvider.vehicles.length,
                    itemBuilder: (context, index) {
                      final v = vehicleProvider.vehicles[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              v.vehicleType == 'motorcycle'
                                  ? Icons.two_wheeler
                                  : Icons.directions_car,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: Text(
                            v.plateNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            '${v.brand} ${v.model} (${v.vehicleTypeThai})',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20),
                                onPressed: () => _showAddCarBottomSheet(v),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('ยืนยันการลบ'),
                                      content: Text('คุณต้องการลบรถทะเบียน ${v.plateNumber} ใช่หรือไม่?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('ลบ'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await vehicleProvider.deleteVehicle(v.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

