import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/school_mgmt_controller.dart';
import 'school_list_view.dart'; 

class ProvinceDashboardContent extends StatelessWidget {
  final SchoolMgmtController controller = Get.find<SchoolMgmtController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // STEP 1: Jika Loading Fetch Kabupaten
      if (controller.isLoading.value && controller.districtList.isEmpty) {
        return Center(child: CircularProgressIndicator());
      }
      
      // STEP 2: Jika belum memilih Kabupaten, tampilkan List Kabupaten
      if (controller.selectedDistrictFilter.value.isEmpty) {
        return _buildDistrictList();
      } 
      // STEP 3: Jika sudah pilih, tampilkan List Sekolah (READ ONLY MODE)
      else {
        return _buildSchoolListWithBackBtn();
      }
    });
  }

  Widget _buildDistrictList() {
    if (controller.districtList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text("Belum ada Admin Kabupaten terdaftar di provinsi ini.", style: TextStyle(color: Colors.grey)),
            Text("Silakan buat akun role 'dinas_kab' terlebih dahulu.", style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text("Pilih Wilayah (${controller.districtList.length})", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: controller.districtList.length,
            itemBuilder: (context, index) {
              final districtName = controller.districtList[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey[300]!)),
                margin: EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.location_city, color: Colors.blue[800]),
                  ),
                  title: Text(districtName, style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () {
                    // AKSI: Load sekolah khusus kabupaten ini
                    controller.loadSchools(districtFilter: districtName);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolListWithBackBtn() {
    return Column(
      children: [
        // Tombol Kembali
        InkWell(
          onTap: () {
            controller.selectedDistrictFilter.value = ''; // Reset filter
            controller.schools.clear(); // Bersihkan list
            controller.totalSekolah.value = 0; // Reset stat visual
          },
          child: Container(
            color: Colors.blue[50],
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.blue[900], size: 20),
                SizedBox(width: 10),
                Text("Kembali ke Daftar Wilayah", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
              ],
            ),
          ),
        ),
        // Panggil SchoolListView dengan Mode READ ONLY (No Tambah Button)
        Expanded(child: SchoolListView(isReadOnly: true)), 
      ],
    );
  }
}