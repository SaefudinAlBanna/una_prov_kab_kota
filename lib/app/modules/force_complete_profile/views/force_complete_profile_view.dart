import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/force_complete_profile_controller.dart';

class ForceCompleteProfileView extends StatelessWidget {
  final controller = Get.put(ForceCompleteProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lengkapi Profil Pegawai"),
        centerTitle: true,
        automaticallyImplyLeading: false, // User gak boleh kabur
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              _buildHeaderInfo(),
              SizedBox(height: 20),
              
              _buildTextField(controller.nipC, "NIP / NUPTK", Icons.badge, isNumber: true),
              SizedBox(height: 15),
              _buildTextField(controller.noHpC, "Nomor WhatsApp Aktif", Icons.phone, isNumber: true),
              SizedBox(height: 15),
              _buildTextField(controller.jabatanC, "Jabatan / Tugas Utama", Icons.work),
              SizedBox(height: 15),
              _buildTextField(controller.alamatC, "Alamat Domisili", Icons.home, maxLines: 3),
              
              SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(() => ElevatedButton.icon(
                  icon: Icon(Icons.save),
                  label: controller.isLoading.value 
                    ? Text("MENYIMPAN...") 
                    : Text("SIMPAN & MASUK DASHBOARD"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: controller.isLoading.value ? null : controller.simpanProfil,
                )),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[900]),
          SizedBox(width: 10),
          Expanded(child: Text("Data ini diperlukan untuk administrasi sekolah dan dinas. Mohon isi dengan benar.")),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
        isDense: true,
      ),
      validator: (val) => (val == null || val.isEmpty) ? "$label wajib diisi" : null,
    );
  }
}