import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';

// IMPORT VIEW SESUAI MODULNYA
import '../../sekolah/views/school_dashboard_view.dart';
import 'items/dashboard_dinas_view.dart'; // View Sekolah Sesi 4

class DashboardView extends GetView<DashboardController> {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Logic Switching: Role Dinas vs Sekolah vs Wali Murid
      
      // 1. DINAS (Provinsi & Kabupaten)
      if (controller.isDinas) {
        return DashboardDinasView();
      } 
      // 2. SEKOLAH (Guru & TU)
      else if (controller.isSekolah) {
        return SchoolDashboardView();
      } 
      // 3. LAIN-LAIN (Wali Murid - Future)
      else {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_clock, size: 50, color: Colors.grey),
                SizedBox(height: 10),
                Text("Modul untuk role '${controller.authC.userModel.value?.role}' belum tersedia."),
                ElevatedButton(
                  onPressed: () => controller.authC.logout(), 
                  child: Text("Logout")
                )
              ],
            ),
          ),
        );
      }
    });
  }
}