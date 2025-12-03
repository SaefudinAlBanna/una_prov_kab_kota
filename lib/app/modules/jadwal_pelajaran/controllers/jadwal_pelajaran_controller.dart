import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/config_controller.dart';
import '../../sekolah/controllers/school_dashboard_controller.dart';

class JadwalPelajaranController extends GetxController with GetTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigController configC = Get.find<ConfigController>();
  final SchoolDashboardController dashC = Get.find<SchoolDashboardController>();

  late TabController tabController;

  final isLoading = true.obs;
  final isLoadingJadwal = false.obs;

  final RxList<Map<String, dynamic>> daftarKelas = <Map<String, dynamic>>[].obs;
  final Rxn<String> selectedKelasId = Rxn<String>();
  
  final RxMap<String, List<Map<String, dynamic>>> jadwalPelajaran = <String, List<Map<String, dynamic>>>{}.obs;
  
  // [PERBAIKAN] Inisialisasi awal dengan data dari Config
  late RxList<String> daftarHari;

  @override
  void onInit() {
    super.onInit();
    // Ambil hari aktif yang sudah disetting di Config
    daftarHari = RxList<String>.from(configC.hariSekolahAktif);
    
    // Inisialisasi awal TabController
    tabController = TabController(length: daftarHari.length, vsync: this);
    _initializeData();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> _initializeData() async {
    isLoading.value = true;
    await _fetchDaftarKelas();
    if (daftarKelas.isNotEmpty) {
      await onKelasChanged(daftarKelas.first['id']);
    }
    isLoading.value = false;
  }

  Future<void> _fetchDaftarKelas() async {
    final tahunAjaran = configC.tahunAjaranAktif.value;
    if (tahunAjaran.isEmpty || tahunAjaran.contains("TIDAK")) return;

    try {
      final snapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('kelas')
          .where('tahunAjaran', isEqualTo: tahunAjaran)
          .orderBy('namaKelas')
          .get();
      
      daftarKelas.value = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id, 
          'nama': data['namaKelas'] ?? doc.id,
          'fase': data['fase'] ?? 'fase_a' 
        };
      }).toList();
    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar kelas: $e");
    }
  }

  Future<void> onKelasChanged(String? kelasId) async {
    if (kelasId == null || kelasId == selectedKelasId.value) return;
    
    selectedKelasId.value = kelasId;
    isLoadingJadwal.value = true;
    jadwalPelajaran.clear();

    // [LOGIKA ADAPTIF BARU]
    // Tidak perlu cek fase lagi, langsung ambil update terbaru dari Config
    // Siapa tahu user baru saja mengubah hari aktif di menu pengaturan
    final hariTerbaru = configC.hariSekolahAktif;

    // Update daftarHari dan TabController jika ada perubahan panjang hari
    if (daftarHari.length != hariTerbaru.length || !daftarHari.every((h) => hariTerbaru.contains(h))) {
      daftarHari.assignAll(hariTerbaru);
      tabController.dispose(); 
      tabController = TabController(length: daftarHari.length, vsync: this);
    } else {
       // Reset ke tab pertama (Senin)
       tabController.animateTo(0);
    }

    try {
      final tahunAjaran = configC.tahunAjaranAktif.value;
      final docSnap = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('jadwalkelas').doc(kelasId)
          .get();

      if (docSnap.exists && docSnap.data() != null) {
        final dataJadwal = docSnap.data()!;
        for (var hari in daftarHari) {
          var pelajaranHari = List<Map<String, dynamic>>.from(dataJadwal[hari] ?? []);
          pelajaranHari.sort((a, b) => (a['jam'] as String).compareTo(b['jam'] as String));
          jadwalPelajaran[hari] = pelajaranHari;
        }
      } else {
        for (var hari in daftarHari) {
          jadwalPelajaran[hari] = [];
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat jadwal: ${e.toString()}');
    } finally {
      isLoadingJadwal.value = false;
    }
  }
}