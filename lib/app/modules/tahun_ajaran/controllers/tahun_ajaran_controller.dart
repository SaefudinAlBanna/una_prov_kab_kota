import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../models/academic_year_model.dart';

class TahunAjaranController extends GetxController {
  final AuthController authC = Get.find<AuthController>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Observable list untuk UI
  var listTahunAjaran = <AcademicYearModel>[].obs;
  var isLoading = false.obs;

  // Text Controller untuk Input
  TextEditingController namaC = TextEditingController(); // misal 2024/2025
  var semesterSelected = "1".obs; // Dropdown value

  @override
  void onInit() {
    super.onInit();
    // Langsung stream data real-time saat controller dipanggil
    bindDataTahunAjaran();
  }

  // 1. STREAM DATA (Realtime Listener)
  void bindDataTahunAjaran() {
    String? idSekolah = authC.userModel.value?.idSekolah;
    if (idSekolah == null) return;

    firestore
        .collection('Sekolah')
        .doc(idSekolah)
        .collection('tahunajaran')
        .orderBy('namatahunajaran', descending: true) // [UBAH] Sorting pakai field baru
        .snapshots()
        .listen((event) {
      listTahunAjaran.value = event.docs
          .map((doc) => AcademicYearModel.fromDocument(doc))
          .toList();
    });
  }

  // 2. TAMBAH DATA BARU
  Future<void> tambahTahunAjaran() async {
    String? idSekolah = authC.userModel.value?.idSekolah;
    if (idSekolah == null || namaC.text.isEmpty) return;

    // VALIDASI FORMAT: Harus ada garis miring (Cth: 2024/2025)
    if (!namaC.text.contains('/')) {
      Get.snackbar("Error", "Format tahun harus pakai garis miring. Cth: 2024/2025");
      return;
    }

    isLoading.value = true;
    try {
      // GENERATE CUSTOM ID: "2024/2025" -> "2024-2025"
      String customDocId = namaC.text.replaceAll('/', '-'); 

      await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(customDocId) // [PENTING] Pakai ID Custom
          .set({ // Gunakan set, bukan add
        'namatahunajaran': namaC.text, // Field Legacy
        'semesterAktif': semesterSelected.value,
        'isAktif': false, // Field Legacy
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      Get.back(); 
      namaC.clear();
      Get.snackbar("Sukses", "Tahun Ajaran berhasil ditambahkan");
    } catch (e) {
      Get.snackbar("Error", "Gagal menambah data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 3. LOGIC SET AKTIF (PENTING!)
  Future<void> setTahunAktif(String idDoc) async {
    String? idSekolah = authC.userModel.value?.idSekolah;
    if (idSekolah == null) return;

    isLoading.value = true;
    WriteBatch batch = firestore.batch();

    try {
      // Step A: Cari yg isAktif == true
      var activeDocs = await firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .where('isAktif', isEqualTo: true) // [UBAH] Field Legacy
          .get();

      // Step B: Matikan
      for (var doc in activeDocs.docs) {
        batch.update(doc.reference, {'isAktif': false}); // [UBAH] Field Legacy
      }

      // Step C: Aktifkan target
      var targetRef = firestore
          .collection('Sekolah')
          .doc(idSekolah)
          .collection('tahunajaran')
          .doc(idDoc);
      
      batch.update(targetRef, {'isAktif': true}); // [UBAH] Field Legacy

      await batch.commit();
      Get.snackbar("Berhasil", "Tahun Ajaran Aktif diperbarui!");

    } catch (e) {
      Get.snackbar("Error", "Gagal mengubah status: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 4. HAPUS DATA
  Future<void> deleteTahun(String idDoc) async {
     String? idSekolah = authC.userModel.value?.idSekolah;
     if (idSekolah == null) return;
     
     try {
       await firestore.collection('Sekolah').doc(idSekolah).collection('tahunajaran').doc(idDoc).delete();
     } catch (e) {
       Get.snackbar("Error", "Gagal menghapus data");
     }
  }
}