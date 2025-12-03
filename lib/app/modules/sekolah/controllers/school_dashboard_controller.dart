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
  
  // [BARU] DATA DETIL PEGAWAI (Dari sub-collection Sekolah)
  final RxString jabatanSistem = "".obs; // Contoh: "Guru Kelas", "Kepala Sekolah"
  final RxList<String> tugasTambahan = <String>[].obs; // Contoh: ["Koordinator Kurikulum"]
  
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
  // 1. GETTERS (UPDATED WITH REAL ROLE LOGIC)
  // ===========================================================================
  String get uid => authC.user!.uid;
  String get idSekolah => authC.userModel.value?.idSekolah ?? '';
  
  // Cek apakah user adalah Dinas (Super Admin)
  bool get isDinas => ['dinas_prov', 'dinas_kab'].contains(authC.userModel.value?.role);

  // [UPDATED] Cek Pimpinan (Kepsek / TU / Dinas)
  bool get isPimpinan {
    if (isDinas) return true;
    final jabatan = jabatanSistem.value; 
    return ['Kepala Sekolah', 'TU', 'Tata Usaha'].contains(jabatan) || 
           tugasTambahan.contains('Admin'); // Admin dianggap pimpinan akademik
  }

  // [UPDATED] Cek Hak Akses Akademik (Penting untuk Menu Jadwal)
  bool get canManageAkademik {
    if (isDinas) return true;
    final jabatan = jabatanSistem.value;
    // Cek Jabatan Utama ATAU Tugas Tambahan
    return ['Kepala Sekolah', 'Koordinator Kurikulum', 'Admin'].contains(jabatan) ||
           tugasTambahan.contains('Koordinator Kurikulum') || 
           tugasTambahan.contains('Admin');
  }

  // [UPDATED] Cek Hak Akses KBM (Sama dengan Akademik untuk saat ini)
  bool get canManageKbm => canManageAkademik;

  bool get isBendaharaOrPimpinan {
    if (isDinas) return true;
    return ['Kepala Sekolah', 'Bendahara'].contains(jabatanSistem.value) || 
           tugasTambahan.contains('Bendahara');
  }
  
  bool get isGuru {
    final jabatan = jabatanSistem.value;
    return ['Guru Kelas', 'Guru Mapel', 'Guru'].contains(jabatan) || 
           jabatan.contains('Guru'); // Flexible check
  }

  // ===========================================================================
  // 2. LIFECYCLE
  // ===========================================================================
  @override
  void onInit() {
    super.onInit();
    loadSchoolData();
    _fetchEmployeeDetail(); // [PENTING] Ambil detail jabatan & tugas
    _syncTahunAjaranAktif();
  }

  @override
  void onReady() {
    super.onReady();
    // Re-trigger menu update saat user model atau detail jabatan berubah
    everAll([authC.userModel, jabatanSistem, tugasTambahan], (_) => _updateMenuLists());
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
        
        // Load Konfigurasi Dashboard
        var configDoc = await firestore.collection('Sekolah').doc(idSekolah)
            .collection('pengaturan').doc('konfigurasi_dashboard').get();
        if(configDoc.exists) konfigurasiDashboard.value = configDoc.data()!;
      }
    } catch (e) {
      print("Error load school data: $e");
    }
  }

  // [BARU] Fungsi Fetch Detail Pegawai
  Future<void> _fetchEmployeeDetail() async {
    if (idSekolah.isEmpty || isDinas) return; // Dinas tidak punya detail pegawai di sekolah

    try {
      var doc = await firestore.collection('Sekolah').doc(idSekolah)
          .collection('pegawai').doc(uid).get();
      
      if (doc.exists) {
        var data = doc.data()!;
        jabatanSistem.value = data['role'] ?? ''; // Ambil Role Spesifik (Guru Kelas dll)
        
        // Ambil Tugas Tambahan (List)
        if (data['tugas'] != null) {
          tugasTambahan.assignAll(List<String>.from(data['tugas']));
        }
        
        print("✅ Logged as: ${jabatanSistem.value}, Tugas: $tugasTambahan");
        // Update menu setelah data didapat
        _updateMenuLists();
      }
    } catch (e) {
      print("Error fetch employee detail: $e");
    }
  }

  void _syncTahunAjaranAktif() {
    if (idSekolah.isEmpty) return;
    
    final query = firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran')
        .where('isAktif', isEqualTo: true)
        .limit(1);

    _tahunAjaranSubscription = query.snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        tahunAjaranAktif.value = doc.id;
        semesterAktif.value = doc.data()['semesterAktif']?.toString() ?? '1';
        
        fetchCarouselData();
        _listenToInfoDashboard();
      } else {
        tahunAjaranAktif.value = "Belum Diset";
      }
    });
  }

  // ===========================================================================
  // 4. LOGIC CAROUSEL
  // ===========================================================================
  Future<void> fetchCarouselData() async {
    isCarouselLoading.value = true;
    try {
      final now = DateTime.now();
      final todayWithoutTime = DateTime(now.year, now.month, now.day);
      
      if (tahunAjaranAktif.value.isEmpty || tahunAjaranAktif.value == "Belum Diset") {
        daftarCarousel.assignAll([
           CarouselItemModel(
             namaKelas: "System", 
             tipeKonten: CarouselContentType.Info, 
             judul: "TAHUN AJARAN", 
             isi: "Belum ada tahun ajaran aktif.", 
             ikon: Icons.warning, 
             warna: Colors.grey
           )
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
            CarouselItemModel(
              namaKelas: "Info Sekolah", 
              tipeKonten: CarouselContentType.Prioritas, 
              judul: "PENGUMUMAN", 
              isi: pesanPimpinan['pesan'] ?? '', 
              ikon: Icons.campaign, 
              warna: Colors.red.shade700
            )
          ]);
          isCarouselLoading.value = false; return;
        }
      }

      // 2. Default Greeting
      daftarCarousel.assignAll([ 
        CarouselItemModel(
          namaKelas: "Umum", 
          tipeKonten: CarouselContentType.PesanDefault, 
          judul: "SELAMAT DATANG", 
          isi: "Selamat bertugas, ${jabatanSistem.value.isEmpty ? 'Pegawai' : jabatanSistem.value}", 
          ikon: Icons.school, 
          warna: Colors.indigo.shade700
        ) 
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
  // 5. MENU GENERATOR (UPDATED)
  // ===========================================================================
  void _updateMenuLists() {
    quickAccessMenus.clear();
    additionalMenus.clear();

    // --- QUICK ACCESS (GRID ATAS) ---
    // Menu dasar untuk semua
    quickAccessMenus.add({
      'image': 'akademik_1.png', 
      'title': 'Tahun Ajaran', 
      'route': '/tahun-ajaran'
    });

    quickAccessMenus.add({
      'image': 'layar_2.png',
      'title': 'Jadwal Pelajaran', 
      'route': Routes.JADWAL_PELAJARAN
    });

    if (isPimpinan || isDinas) {
       quickAccessMenus.add({'image': 'papan_list.png', 'title': 'Laporan', 'onTap': () => Get.snackbar("Info", "Fitur Laporan segera hadir")});
    }
    
    // Menu Khusus Guru
    if (isGuru) {
       quickAccessMenus.add({'image': 'jurnal_ajar.png', 'title': 'Jurnal Mengajar', 'onTap': () {}});
    }

    quickAccessMenus.add({'image': 'faq.png', 'title': 'Lainnya', 'onTap': () => _showAllMenusInView()});

    // --- ADDITIONAL MENUS (GRID BAWAH/DRAWER) ---
    // [LOGIC MENU DINAMIS BERDASARKAN TUGAS]
    
    // Semua Pegawai bisa lihat teman sejawat & siswa
    additionalMenus.add({'image': 'daftar_list.png', 'title': 'Data Pegawai', 'route': Routes.PEGAWAI});
    additionalMenus.add({'image': 'daftar_tes.png', 'title': 'Data Siswa', 'route': Routes.DAFTAR_SISWA});
    
    // Hanya Wali Kelas / Pimpinan / Kesiswaan
    if (isGuru || canManageAkademik) { 
        additionalMenus.add({'image': 'kamera_layar.png', 'title': 'Master Kelas', 'route': '/master-kelas'});
        additionalMenus.add({'image': 'layar_list.png', 'title': 'Atur Kelas', 'route': Routes.PEMBERIAN_KELAS_SISWA});
    }
    
    // Hanya Kurikulum / Pimpinan
    if (isPimpinan) {
      additionalMenus.add({'image': 'pengumuman.png', 'title': 'Pengaturan', 'onTap': () => Get.toNamed(Routes.MANAJEMEN_PERAN)});
    }
  }

  void _showAllMenusInView() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.5,
        color: Colors.white,
        child: GridView.count(
          crossAxisCount: 4,
          padding: EdgeInsets.all(16),
          children: additionalMenus.map((menu) {
             return InkWell(
               onTap: menu['route'] != null ? () => Get.toNamed(menu['route']) : menu['onTap'],
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   // Ganti Image.asset dengan Icon jika gambar belum ada
                   Icon(Icons.folder, color: Colors.blue, size: 30),
                   SizedBox(height: 5),
                   Text(menu['title'], textAlign: TextAlign.center, style: TextStyle(fontSize: 10))
                 ],
               ),
             );
          }).toList(),
        ),
      )
    );
  }
}


// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:una_digital_provinsi/app/controllers/config_controller.dart';
// import '../../../controllers/auth_controller.dart';
// import '../../../models/carousel_item_model.dart';
// import '../../../routes/app_pages.dart';

// class SchoolDashboardController extends GetxController {
//   final AuthController authC = Get.find<AuthController>();
//   final ConfigController configC = Get.find<ConfigController>();
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;

//   // --- DATA SEKOLAH & USER ---
//   RxString namaSekolah = "Memuat...".obs;
//   RxString npsn = "-".obs;
//   RxString tahunAjaranAktif = "".obs;
//   RxString semesterAktif = "".obs;
  
//   // --- CAROUSEL & DASHBOARD PROPS ---
//   final RxBool isCarouselLoading = true.obs;
//   final RxList<CarouselItemModel> daftarCarousel = <CarouselItemModel>[].obs;
//   final RxList<DocumentSnapshot> daftarInfoSekolah = <DocumentSnapshot>[].obs;
  
//   // --- MENU MANAGEMENT ---
//   final RxList<Map<String, dynamic>> quickAccessMenus = <Map<String, dynamic>>[].obs;
//   final RxList<Map<String, dynamic>> additionalMenus = <Map<String, dynamic>>[].obs;
//   final RxMap<String, dynamic> konfigurasiDashboard = <String, dynamic>{}.obs;

//   StreamSubscription? _tahunAjaranSubscription;
//   StreamSubscription? _infoDashboardSubscription;

//   // ===========================================================================
//   // 1. GETTERS (ROLE & PERMISSION LOGIC) - Ported from Legacy
//   // ===========================================================================
//   String get uid => authC.user!.uid;
//   String get idSekolah => authC.userModel.value?.idSekolah ?? '';
  
//   // Helper Helper untuk mapping data user model ke logic lama
//   String get _userRole => authC.userModel.value?.role ?? ''; // Perlu disesuaikan jika role di db disimpan sbg 'Jabatan'
//   // Catatan: Di project baru 'role' utama adalah 'pegawai'. Jabatan spesifik mungkin ada di field lain?
//   // Asumsi: Kita ambil role detail dari field 'jabatan' atau 'peranSistem' jika ada di UserModel tambahan, 
//   // tapi sementara kita pakai logika string sederhana.
  
//   bool get isKepalaSekolah => _checkRole(['Kepala Sekolah']);
  
//   bool get isPimpinan => 
//       ['Kepala Sekolah', 'TU', 'Tata Usaha'].contains(_userRole) || 
//       (authC.userModel.value?.role == 'dinas_prov'); // Dinas dianggap pimpinan intip

//   bool get isBendaharaOrPimpinan => ['Kepala Sekolah', 'Bendahara'].contains(_userRole);
  
//   bool get isGuru => ['Guru Kelas', 'Guru Mapel'].contains(_userRole);

//   bool get canManageAkademik => 
//       ['Kepala Sekolah', 'Koordinator Kurikulum'].contains(_userRole) || isSuperAdmin ||
//       (configC.infoUser['tugas'] == 'Koordinator Kurikulum');

//   bool get isSuperAdmin => authC.userModel.value?.role == 'dinas_prov' || authC.userModel.value?.role == 'dinas_kab'; // Logic sementara

//   // Fungsi helper cek role (bisa dikembangkan)
//   bool _checkRole(List<String> allowed) {
//     // Implementasi sederhana, bisa diganti logic cek field 'jabatan' di Firestore
//     return allowed.contains(_userRole);
//   }

//   // ===========================================================================
//   // 2. LIFECYCLE
//   // ===========================================================================
//   @override
//   void onInit() {
//     super.onInit();
//     loadSchoolData();
//     _syncTahunAjaranAktif();
//   }

//   @override
//   void onReady() {
//     super.onReady();
//     // Re-trigger menu update saat user model berubah
//     ever(authC.userModel, (_) => _updateMenuLists());
//     _updateMenuLists();
//   }

//   @override
//   void onClose() {
//     _tahunAjaranSubscription?.cancel();
//     _infoDashboardSubscription?.cancel();
//     super.onClose();
//   }

//   // ===========================================================================
//   // 3. DATA SYNCING
//   // ===========================================================================
//   Future<void> loadSchoolData() async {
//     if (idSekolah.isEmpty) return;
//     try {
//       var doc = await firestore.collection('Sekolah').doc(idSekolah).get();
//       if (doc.exists) {
//         var data = doc.data()!;
//         namaSekolah.value = data['nama'] ?? "Nama Tidak Ada";
//         npsn.value = data['npsn'] ?? "-";
        
//         // Load Konfigurasi Dashboard (Pesan Pimpinan, dll)
//         var configDoc = await firestore.collection('Sekolah').doc(idSekolah)
//             .collection('pengaturan').doc('konfigurasi_dashboard').get();
//         if(configDoc.exists) konfigurasiDashboard.value = configDoc.data()!;
//       }
//     } catch (e) {
//       print("Error load school data: $e");
//     }
//   }

//   void _syncTahunAjaranAktif() {
//     if (idSekolah.isEmpty) return;
    
//     // Query dokumen Tahun Ajaran yang 'isAktive == true' (Sesuai model baru Anda)
//     final query = firestore.collection('Sekolah').doc(idSekolah)
//         .collection('tahunajaran')
//         .where('isAktif', isEqualTo: true)
//         .limit(1);

//     _tahunAjaranSubscription = query.snapshots().listen((snapshot) {
//       if (snapshot.docs.isNotEmpty) {
//         final doc = snapshot.docs.first;
//         tahunAjaranAktif.value = doc.id;
//         semesterAktif.value = doc.data()['semesterAktif']?.toString() ?? '1';
        
//         // Setelah dapat TA, muat Carousel & Info
//         fetchCarouselData();
//         _listenToInfoDashboard();
//       } else {
//         tahunAjaranAktif.value = "Belum Diset";
//       }
//     });
//   }

//   // ===========================================================================
//   // 4. LOGIC CAROUSEL (PORTED)
//   // ===========================================================================
//   Future<void> fetchCarouselData() async {
//     isCarouselLoading.value = true;
//     try {
//       final now = DateTime.now();
//       final todayWithoutTime = DateTime(now.year, now.month, now.day);
      
//       if (tahunAjaranAktif.value.isEmpty || tahunAjaranAktif.value == "Belum Diset") {
//         daftarCarousel.assignAll([
//            CarouselItemModel(
//              namaKelas: "System", 
//              tipeKonten: CarouselContentType.Info, // Enum Baru
//              judul: "TAHUN AJARAN", 
//              isi: "Belum ada tahun ajaran aktif.", 
//              ikon: Icons.warning, 
//              warna: Colors.grey
//            )
//         ]);
//         isCarouselLoading.value = false;
//         return;
//       }

//       // 1. Cek Pesan Pimpinan (Prioritas)
//       final pesanPimpinan = konfigurasiDashboard['pesanPimpinan'] as Map<String, dynamic>?;
//       if (pesanPimpinan != null) {
//         final berlakuHingga = (pesanPimpinan['berlakuHingga'] as Timestamp?)?.toDate();
//         if (berlakuHingga != null && now.isBefore(berlakuHingga)) {
//           daftarCarousel.assignAll([
//             CarouselItemModel(
//               namaKelas: "Info Sekolah", 
//               tipeKonten: CarouselContentType.Prioritas, // Enum Baru
//               judul: "PENGUMUMAN", 
//               isi: pesanPimpinan['pesan'] ?? '', 
//               ikon: Icons.campaign, 
//               warna: Colors.red.shade700
//             )
//           ]);
//           isCarouselLoading.value = false; return;
//         }
//       }

//       // 2. Cek Hari Libur / Kalender
//       try {
//         final kalenderSnap = await firestore.collection('Sekolah').doc(idSekolah)
//             .collection('tahunajaran').doc(tahunAjaranAktif.value)
//             .collection('kalender_akademik')
//             .where('tanggalMulai', isLessThanOrEqualTo: now).get();
            
//         for (var doc in kalenderSnap.docs) {
//           final data = doc.data();
//           final tglSelesai = (data['tanggalSelesai'] as Timestamp).toDate();
//           if (todayWithoutTime.isBefore(tglSelesai.add(const Duration(days: 1)))) {
//              daftarCarousel.assignAll([ 
//                CarouselItemModel(
//                  namaKelas: "Info", 
//                  tipeKonten: CarouselContentType.Info, 
//                  judul: "AGENDA", 
//                  isi: data['namaKegiatan'] ?? '', 
//                  ikon: Icons.event, 
//                  warna: Colors.teal
//                ) 
//              ]);
//              isCarouselLoading.value = false; return;
//           }
//         }
//       } catch (e) { }

//       // 3. Default Weekend
//       if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
//          daftarCarousel.assignAll([ 
//            CarouselItemModel(
//              namaKelas: "Weekend", 
//              tipeKonten: CarouselContentType.PesanDefault, // Enum Baru
//              judul: "HAPPY WEEKEND", 
//              isi: "Selamat berakhir pekan!", 
//              ikon: Icons.weekend, 
//              warna: Colors.blue.shade600
//            ) 
//          ]);
//          isCarouselLoading.value = false; return;
//       }

//       // 4. Default Greeting
//       daftarCarousel.assignAll([ 
//         CarouselItemModel(
//           namaKelas: "Umum", 
//           tipeKonten: CarouselContentType.PesanDefault, // Enum Baru
//           judul: "SELAMAT DATANG", 
//           isi: "Selamat bertugas di ${namaSekolah.value}", 
//           ikon: Icons.school, 
//           warna: Colors.indigo.shade700
//         ) 
//       ]);

//     } catch (e) {
//       print("Error fetching carousel: $e");
//     } finally {
//       isCarouselLoading.value = false;
//     }
//   }

//   void _listenToInfoDashboard() {
//     _infoDashboardSubscription?.cancel();
//     if (tahunAjaranAktif.value.isEmpty) return;

//     _infoDashboardSubscription = firestore.collection('Sekolah').doc(idSekolah)
//         .collection('tahunajaran').doc(tahunAjaranAktif.value)
//         .collection('info_sekolah')
//         .orderBy('timestamp', descending: true)
//         .limit(5)
//         .snapshots().listen((snapshot) {
//             daftarInfoSekolah.assignAll(snapshot.docs);
//         });
//   }

//   // ===========================================================================
//   // 5. MENU GENERATOR (PORTED & ADAPTED)
//   // ===========================================================================
//   void _updateMenuLists() {
//     quickAccessMenus.clear();
//     additionalMenus.clear();

//     // --- QUICK ACCESS (GRID ATAS) ---
//     // Menu "Tahun Ajaran" yang baru kita buat
//     quickAccessMenus.add({
//       'image': 'akademik_1.png', // Pastikan aset ada, atau nanti handle error image
//       'title': 'Tahun Ajaran', 
//       'route': '/tahun-ajaran'
//     });

//     quickAccessMenus.add({
//       'image': 'ktp.png', // Pastikan aset ada, atau nanti handle error image
//       'title': 'pegawai', 
//       'route': Routes.PEGAWAI
//     });

//     quickAccessMenus.add({
//       'image': 'layar_list.png', // Pastikan aset ada, atau nanti handle error image
//       'title': 'Pemberian Kelas', 
//       'route': Routes.PEMBERIAN_KELAS_SISWA
//     });

//     quickAccessMenus.add({
//       'image': 'daftar_tes.png', // Pastikan aset ada, atau nanti handle error image
//       'title': 'Daftar Siswa', 
//       'route': Routes.DAFTAR_SISWA
//     });

//     quickAccessMenus.add({
//       'image': 'layar_2.png', // Pastikan aset ada, atau nanti handle error image
//       'title': 'Jadwal Pelajaran', 
//       'route': Routes.JADWAL_PELAJARAN
//     });

//     if (isKepalaSekolah || isSuperAdmin) {
//        quickAccessMenus.add({'image': 'papan_list.png', 'title': 'Laporan', 'onTap': () => Get.snackbar("Info", "Fitur Laporan segera hadir")});
//     }
    
//     if (isGuru) {
//        quickAccessMenus.add({'image': 'jurnal_ajar.png', 'title': 'Jurnal Mengajar', 'onTap': () {}});
//        quickAccessMenus.add({'image': 'abc.png', 'title': 'Jadwal Saya', 'onTap': () {}});
//     }

//     quickAccessMenus.add({'image': 'faq.png', 'title': 'Lainnya', 'onTap': () => _showAllMenusInView()});

//     // --- ADDITIONAL MENUS (GRID BAWAH/DRAWER) ---
//     // Masukkan semua menu lengkap disini
//     // additionalMenus.add({'image': 'daftar_list.png', 'title': 'Data Pegawai', 'onTap': () {}});
//         additionalMenus.add({
//       'image': 'daftar_list.png', // Ganti icon yg sesuai
//       'title': 'Data Pegawai', 
//       'route': Routes.PEGAWAI // Pastikan constant stringnya '/pegawai'
//     });
//     additionalMenus.add({'image': 'daftar_tes.png', 'title': 'Data Siswa', 'onTap': () {}});
//     additionalMenus.add({'image': 'kamera_layar.png', 'title': 'Data Kelas', 'onTap': () {}});
    
//     if (canManageAkademik) {
//       additionalMenus.add({'image': 'pengumuman.png', 'title': 'Pengaturan', 'onTap': () {}});
//     }
//   }

//   void _showAllMenusInView() {
//     // Logic BottomSheet untuk menampilkan semua menu
//     // Bisa copy logic dari controller lama jika diperlukan
//   }
// }