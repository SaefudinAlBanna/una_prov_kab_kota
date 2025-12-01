import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/carousel_item_model.dart';
import '../../../routes/app_pages.dart';

class SchoolDashboardController extends GetxController {
  final AuthController authC = Get.find<AuthController>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // --- DATA SEKOLAH & USER ---
  RxString namaSekolah = "Memuat...".obs;
  RxString npsn = "-".obs;
  RxString tahunAjaranAktif = "".obs;
  RxString semesterAktif = "".obs;
  
  // --- CAROUSEL & DASHBOARD PROPS ---
  final RxBool isCarouselLoading = true.obs;
  final RxList<CarouselItemModel> daftarCarousel = <CarouselItemModel>[].obs;
  final RxList<DocumentSnapshot> daftarInfoSekolah = <DocumentSnapshot>[].obs;
  
  // --- MENU MANAGEMENT ---
  final RxList<Map<String, dynamic>> quickAccessMenus = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> additionalMenus = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> konfigurasiDashboard = <String, dynamic>{}.obs;

  StreamSubscription? _tahunAjaranSubscription;
  StreamSubscription? _infoDashboardSubscription;

  // ===========================================================================
  // 1. GETTERS (ROLE & PERMISSION LOGIC) - Ported from Legacy
  // ===========================================================================
  String get uid => authC.user!.uid;
  String get idSekolah => authC.userModel.value?.idSekolah ?? '';
  
  // Helper Helper untuk mapping data user model ke logic lama
  String get _userRole => authC.userModel.value?.role ?? ''; // Perlu disesuaikan jika role di db disimpan sbg 'Jabatan'
  // Catatan: Di project baru 'role' utama adalah 'pegawai'. Jabatan spesifik mungkin ada di field lain?
  // Asumsi: Kita ambil role detail dari field 'jabatan' atau 'peranSistem' jika ada di UserModel tambahan, 
  // tapi sementara kita pakai logika string sederhana.
  
  bool get isKepalaSekolah => _checkRole(['Kepala Sekolah']);
  
  bool get isPimpinan => 
      ['Kepala Sekolah', 'Koordinator Kurikulum', 'TU', 'Tata Usaha'].contains(_userRole) || 
      (authC.userModel.value?.role == 'dinas_prov'); // Dinas dianggap pimpinan intip

  bool get isBendaharaOrPimpinan => ['Kepala Sekolah', 'Bendahara'].contains(_userRole);
  
  bool get isGuru => ['Guru Kelas', 'Guru Mapel'].contains(_userRole);

  bool get canManageAkademik => 
      ['Kepala Sekolah', 'Koordinator Kurikulum'].contains(_userRole) || isSuperAdmin;

  bool get isSuperAdmin => authC.userModel.value?.role == 'dinas_prov' || authC.userModel.value?.role == 'dinas_kab'; // Logic sementara

  // Fungsi helper cek role (bisa dikembangkan)
  bool _checkRole(List<String> allowed) {
    // Implementasi sederhana, bisa diganti logic cek field 'jabatan' di Firestore
    return allowed.contains(_userRole);
  }

  // ===========================================================================
  // 2. LIFECYCLE
  // ===========================================================================
  @override
  void onInit() {
    super.onInit();
    loadSchoolData();
    _syncTahunAjaranAktif();
  }

  @override
  void onReady() {
    super.onReady();
    // Re-trigger menu update saat user model berubah
    ever(authC.userModel, (_) => _updateMenuLists());
    _updateMenuLists();
  }

  @override
  void onClose() {
    _tahunAjaranSubscription?.cancel();
    _infoDashboardSubscription?.cancel();
    super.onClose();
  }

  // ===========================================================================
  // 3. DATA SYNCING
  // ===========================================================================
  Future<void> loadSchoolData() async {
    if (idSekolah.isEmpty) return;
    try {
      var doc = await firestore.collection('Sekolah').doc(idSekolah).get();
      if (doc.exists) {
        var data = doc.data()!;
        namaSekolah.value = data['nama'] ?? "Nama Tidak Ada";
        npsn.value = data['npsn'] ?? "-";
        
        // Load Konfigurasi Dashboard (Pesan Pimpinan, dll)
        var configDoc = await firestore.collection('Sekolah').doc(idSekolah)
            .collection('pengaturan').doc('konfigurasi_dashboard').get();
        if(configDoc.exists) konfigurasiDashboard.value = configDoc.data()!;
      }
    } catch (e) {
      print("Error load school data: $e");
    }
  }

  void _syncTahunAjaranAktif() {
    if (idSekolah.isEmpty) return;
    
    // Query dokumen Tahun Ajaran yang 'isAktive == true' (Sesuai model baru Anda)
    final query = firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran')
        .where('isAktif', isEqualTo: true)
        .limit(1);

    _tahunAjaranSubscription = query.snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        tahunAjaranAktif.value = doc.id;
        semesterAktif.value = doc.data()['semesterAktif']?.toString() ?? '1';
        
        // Setelah dapat TA, muat Carousel & Info
        fetchCarouselData();
        _listenToInfoDashboard();
      } else {
        tahunAjaranAktif.value = "Belum Diset";
      }
    });
  }

  // ===========================================================================
  // 4. LOGIC CAROUSEL (PORTED)
  // ===========================================================================
  Future<void> fetchCarouselData() async {
    isCarouselLoading.value = true;
    try {
      final now = DateTime.now();
      final todayWithoutTime = DateTime(now.year, now.month, now.day);
      
      if (tahunAjaranAktif.value.isEmpty || tahunAjaranAktif.value == "Belum Diset") {
        daftarCarousel.assignAll([
           CarouselItemModel(namaKelas: "System", tipe: CarouselContentType.Info, judul: "TAHUN AJARAN", isi: "Belum ada tahun ajaran aktif.", ikon: Icons.warning, warna: Colors.grey)
        ]);
        isCarouselLoading.value = false;
        return;
      }

      // 1. Cek Pesan Pimpinan
      final pesanPimpinan = konfigurasiDashboard['pesanPimpinan'] as Map<String, dynamic>?;
      if (pesanPimpinan != null) {
        final berlakuHingga = (pesanPimpinan['berlakuHingga'] as Timestamp?)?.toDate();
        if (berlakuHingga != null && now.isBefore(berlakuHingga)) {
          daftarCarousel.assignAll([
            CarouselItemModel(namaKelas: "Info Sekolah", tipe: CarouselContentType.Prioritas, judul: "PENGUMUMAN", isi: pesanPimpinan['pesan'] ?? '', ikon: Icons.campaign, warna: Colors.red.shade700)
          ]);
          isCarouselLoading.value = false; return;
        }
      }

      // 2. Cek Hari Libur (Kalender Akademik)
      // Logic ini butuh collection 'kalender_akademik' yg mungkin belum ada isinya, kita skip/try-catch
      try {
        final kalenderSnap = await firestore.collection('Sekolah').doc(idSekolah)
            .collection('tahunajaran').doc(tahunAjaranAktif.value)
            .collection('kalender_akademik')
            .where('tanggalMulai', isLessThanOrEqualTo: now).get();
            
        for (var doc in kalenderSnap.docs) {
          final data = doc.data();
          final tglSelesai = (data['tanggalSelesai'] as Timestamp).toDate();
          if (todayWithoutTime.isBefore(tglSelesai.add(const Duration(days: 1)))) {
             daftarCarousel.assignAll([ CarouselItemModel(namaKelas: "Info", tipe: CarouselContentType.Info, judul: "AGENDA", isi: data['namaKegiatan'] ?? '', ikon: Icons.event, warna: Colors.teal) ]);
             isCarouselLoading.value = false; return;
          }
        }
      } catch (e) { /* Ignore if collection not found */ }

      // 3. Default Weekend
      if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
         daftarCarousel.assignAll([ CarouselItemModel(namaKelas: "Weekend", tipe: CarouselContentType.Default, judul: "HAPPY WEEKEND", isi: "Selamat berakhir pekan!", ikon: Icons.weekend, warna: Colors.blue.shade600) ]);
         isCarouselLoading.value = false; return;
      }

      // 4. Default Greeting
      daftarCarousel.assignAll([ 
        CarouselItemModel(namaKelas: "Umum", tipe: CarouselContentType.Default, judul: "SELAMAT DATANG", isi: "Selamat bertugas di ${namaSekolah.value}", ikon: Icons.school, warna: Colors.indigo.shade700) 
      ]);

    } catch (e) {
      print("Error fetching carousel: $e");
    } finally {
      isCarouselLoading.value = false;
    }
  }

  void _listenToInfoDashboard() {
    _infoDashboardSubscription?.cancel();
    if (tahunAjaranAktif.value.isEmpty) return;

    _infoDashboardSubscription = firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran').doc(tahunAjaranAktif.value)
        .collection('info_sekolah')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots().listen((snapshot) {
            daftarInfoSekolah.assignAll(snapshot.docs);
        });
  }

  // ===========================================================================
  // 5. MENU GENERATOR (PORTED & ADAPTED)
  // ===========================================================================
  void _updateMenuLists() {
    quickAccessMenus.clear();
    additionalMenus.clear();

    // --- QUICK ACCESS (GRID ATAS) ---
    // Menu "Tahun Ajaran" yang baru kita buat
    quickAccessMenus.add({
      'image': 'akademik_1.png', // Pastikan aset ada, atau nanti handle error image
      'title': 'Tahun Ajaran', 
      'route': '/tahun-ajaran'
    });

    if (isKepalaSekolah || isSuperAdmin) {
       quickAccessMenus.add({'image': 'papan_list.png', 'title': 'Laporan', 'onTap': () => Get.snackbar("Info", "Fitur Laporan segera hadir")});
    }
    
    if (isGuru) {
       quickAccessMenus.add({'image': 'jurnal_ajar.png', 'title': 'Jurnal Mengajar', 'onTap': () {}});
       quickAccessMenus.add({'image': 'abc.png', 'title': 'Jadwal Saya', 'onTap': () {}});
    }

    quickAccessMenus.add({'image': 'faq.png', 'title': 'Lainnya', 'onTap': () => _showAllMenusInView()});

    // --- ADDITIONAL MENUS (GRID BAWAH/DRAWER) ---
    // Masukkan semua menu lengkap disini
    additionalMenus.add({'image': 'daftar_list.png', 'title': 'Data Pegawai', 'onTap': () {}});
    additionalMenus.add({'image': 'daftar_tes.png', 'title': 'Data Siswa', 'onTap': () {}});
    additionalMenus.add({'image': 'kamera_layar.png', 'title': 'Data Kelas', 'onTap': () {}});
    
    if (canManageAkademik) {
      additionalMenus.add({'image': 'pengumuman.png', 'title': 'Pengaturan', 'onTap': () {}});
    }
  }

  void _showAllMenusInView() {
    // Logic BottomSheet untuk menampilkan semua menu
    // Bisa copy logic dari controller lama jika diperlukan
  }
}


// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import '../../../controllers/auth_controller.dart';
// import '../../../services/app_config.dart';

// class SchoolDashboardController extends GetxController {
//   final AuthController authC = Get.find<AuthController>();
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;

//   // Data Sekolah Dasar
//   RxString namaSekolah = "Memuat...".obs;
//   RxString npsn = "-".obs;
  
//   // --- MIGRASI DARI LEGACY CODE (ConfigController) ---
//   RxString tahunAjaranAktif = "".obs;
//   RxString semesterAktif = "".obs;
//   RxBool isWaliKelas = false.obs;
//   RxString idKelasDiampu = "".obs; // Jika dia wali kelas
  
//   // Statistik Deep Learning
//   RxDouble moodIndex = 0.0.obs;

//   StreamSubscription? _tahunAjaranSubscription;

//   @override
//   void onInit() {
//     super.onInit();
//     // Jalankan init
//     loadSchoolData();
//     _syncTahunAjaranAktif(); // Start listening TA
//   }

//   @override
//   void onClose() {
//     _tahunAjaranSubscription?.cancel();
//     super.onClose();
//   }

//   Future<void> loadSchoolData() async {
//     String? schoolId = authC.userModel.value?.idSekolah;
    
//     if (schoolId != null && schoolId.isNotEmpty) {
//       try {
//         var doc = await firestore.collection('Sekolah').doc(schoolId).get();
//         if (doc.exists) {
//           var data = doc.data()!;
//           namaSekolah.value = data['nama'] ?? "Nama Tidak Ada";
//           npsn.value = data['npsn'] ?? "-";
//         }
//       } catch (e) {
//         print("Error load school data: $e");
//       }
//     }
//   }

//   // --- LOGIC PORTING: TAHUN AJARAN AKTIF ---
//   void _syncTahunAjaranAktif() {
//     String? schoolId = authC.userModel.value?.idSekolah;
//     if (schoolId == null) return;

//     print("📆 [SchoolController] Syncing Tahun Ajaran...");
    
//     // Query dokumen Tahun Ajaran yang 'isAktif == true'
//     final query = firestore.collection('Sekolah').doc(schoolId)
//         .collection('tahunajaran')
//         .where('isAktif', isEqualTo: true)
//         .limit(1);

//     _tahunAjaranSubscription = query.snapshots().listen((snapshot) {
//       if (snapshot.docs.isNotEmpty) {
//         final doc = snapshot.docs.first;
//         tahunAjaranAktif.value = doc.id; // ID Dokumen misal "2024-2025"
//         semesterAktif.value = doc.data()['semesterAktif']?.toString() ?? '1';
        
//         print("✅ [SchoolController] TA Aktif: ${tahunAjaranAktif.value}, Sem: ${semesterAktif.value}");
        
//         // Setelah dapat TA, cek apakah user ini Wali Kelas di TA ini?
//         _checkIsWaliKelas(schoolId, tahunAjaranAktif.value);
        
//       } else {
//         tahunAjaranAktif.value = "Belum Diset";
//         semesterAktif.value = "-";
//       }
//     }, onError: (e) {
//       print("❌ Error Sync TA: $e");
//     });
//   }

//   // --- LOGIC PORTING: CEK WALI KELAS ---
//   Future<void> _checkIsWaliKelas(String schoolId, String taId) async {
//     String uid = authC.user!.uid;
    
//     try {
//       final snapshot = await firestore
//           .collection('Sekolah').doc(schoolId)
//           .collection('tahunajaran').doc(taId)
//           .collection('kelastahunajaran') // Collection Rombel
//           .where('idWaliKelas', isEqualTo: uid)
//           .limit(1)
//           .get();

//       if (snapshot.docs.isNotEmpty) {
//         isWaliKelas.value = true;
//         idKelasDiampu.value = snapshot.docs.first.id;
//         print("👨‍🏫 [SchoolController] User adalah Wali Kelas: ${idKelasDiampu.value}");
//       } else {
//         isWaliKelas.value = false;
//         idKelasDiampu.value = "";
//       }
//     } catch (e) {
//       print("❌ Error Cek Wali Kelas: $e");
//     }
//   }

//   // Navigasi
//   void toAkreditasi() {
//     if (AppConfig.to.enableAkreditasiData) {
//        Get.snackbar("Info", "Modul Akreditasi siap dibangun.");
//     }
//   }

//   void toDeepLearningJournal() {
//     if (AppConfig.to.enableDeepLearning) {
//       Get.snackbar("Deep Learning", "Menu Jurnal Mindful, Meaningful, Joyful.");
//     }
//   }
// }