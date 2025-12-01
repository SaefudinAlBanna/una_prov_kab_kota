import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../dinas/controllers/school_mgmt_controller.dart';
import '../../../dinas/views/school_list_view.dart';
import '../../../dinas/views/province_dashboard_content.dart'; // Pastikan Import Ini Ada
import '../../controllers/dashboard_controller.dart';

class DashboardDinasView extends GetView<DashboardController> {
  // Inject SchoolMgmtController
  final SchoolMgmtController schoolC = Get.put(SchoolMgmtController());

  DashboardDinasView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String wilayahDisplay = "Memuat...";
    var user = controller.authC.userModel.value;
    if (user != null) {
      if (user.role == 'dinas_prov') {
        wilayahDisplay = "Provinsi ${user.scopeProv ?? '-'}";
      } else {
        wilayahDisplay = "${user.scopeDist ?? '-'}";
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Command Center Dinas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900], 
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => controller.authC.logout(), 
            icon: const Icon(Icons.logout, color: Colors.white)
          )
        ],
      ),
      body: Column(
        children: [
          // HEADER STATISTIK (Sama seperti sebelumnya)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${controller.greeting},", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          Text(controller.authC.userModel.value?.nama ?? 'Admin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50], borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue[100]!)
                        ),
                        child: Text(wilayahDisplay, style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Obx(() => Row(
                  children: [
                    _buildStatCard("Total Sekolah", "${schoolC.totalSekolah.value}", Colors.orange, Icons.school),
                    const SizedBox(width: 15),
                    _buildStatCard("Est. Siswa", "${schoolC.totalSiswaEstimasi.value}", Colors.blue, Icons.people),
                  ],
                )),
              ],
            ),
          ),

          // --- [FIXED] KONTEN DINAMIS BERDASARKAN ROLE ---
          Expanded(
            child: Container(
              color: Colors.grey[50],
              // Disini logicnya: Jika Provinsi -> ProvinceContent, Jika Kab -> SchoolList
              child: _buildRoleContent(), 
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget
  Widget _buildRoleContent() {
    // Ambil role dari AuthController
    final role = controller.authC.userModel.value?.role;
    
    if (role == 'dinas_prov') {
      // Provinsi melihat Daftar Kabupaten dulu
      return ProvinceDashboardContent();
    } else {
      // Kabupaten langsung melihat Daftar Sekolah (Dan bisa tambah)
      return SchoolListView(isReadOnly: false); 
    }
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(width: 15),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ]),
          ],
        ),
      ),
    );
  }
}