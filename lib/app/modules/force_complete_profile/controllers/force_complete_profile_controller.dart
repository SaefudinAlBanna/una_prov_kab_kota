import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';

class ForceCompleteProfileController extends GetxController {
  final AuthController _authC = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final formKey = GlobalKey<FormState>();
  
  // Controller Text Field (Data Pegawai)
  final nipC = TextEditingController();
  final noHpC = TextEditingController();
  final alamatC = TextEditingController();
  final jabatanC = TextEditingController(); // e.g. Guru Matematika
  
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Prefill data jika ada (dari user model)
    var user = _authC.userModel.value;
    if (user != null) {
      if (user.nip != null) nipC.text = user.nip!;
      if (user.noHp != null) noHpC.text = user.noHp!;
    }
  }

  Future<void> simpanProfil() async {
    if (!formKey.currentState!.validate()) return;
    
    isLoading.value = true;
    try {
      String uid = _authC.user!.uid;
      String schoolId = _authC.userModel.value!.idSekolah!;

      Map<String, dynamic> dataUpdate = {
        'nip': nipC.text.trim(),
        'noHp': noHpC.text.trim(),
        'alamat': alamatC.text.trim(),
        'jabatan': jabatanC.text.trim(),
        'isProfileComplete': true, // Kunci sukses!
      };

      // 1. Update di Collection 'users' (Global Access)
      await _firestore.collection('users').doc(uid).update(dataUpdate);

      // 2. Update di Sub-Collection 'Sekolah/pegawai' (Detail Sekolah)
      await _firestore.collection('Sekolah').doc(schoolId)
          .collection('pegawai').doc(uid).update(dataUpdate);

      Get.snackbar("Selesai", "Profil Anda sudah lengkap!", backgroundColor: Colors.green[100]);
      
      // RELOAD USER -> TRIGGER NAVIGASI DASHBOARD
      await _authC.loadUser();

    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan data: $e", backgroundColor: Colors.red[100]);
    } finally {
      isLoading.value = false;
    }
  }
}