import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

enum AppStatus { loading, unauthenticated, authenticated }

class ConfigController extends GetxController {
  final AuthController authC = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===========================================================================
  // 1. ADAPTASI LEGACY (Jembatan ke Kode Lama)
  // ===========================================================================
  
  // Mengambil ID Sekolah dari AuthController
  String get idSekolah => authC.userModel.value?.idSekolah ?? '';
  
  // Mengubah UserModel menjadi Map agar kompatibel dengan Controller lama
  Map<String, dynamic> get infoUser {
    final user = authC.userModel.value;
    if (user == null) return {};
    
    return {
      'uid': user.uid,
      'nama': user.nama,
      'email': user.email,
      'fotoUrl': user.fotoUrl,
      // Default 'superadmin' agar Admin Sekolah punya akses penuh
      'peranSistem': 'superadmin', 
      'role': user.role, // role sistem (pegawai)
      'tugas': [], // Tugas tambahan dihandle oleh SchoolDashboardController
    };
  }

  // ===========================================================================
  // 2. STATE VARIABLES
  // ===========================================================================

  final Rx<AppStatus> status = AppStatus.loading.obs; 
  final RxString tahunAjaranAktif = "".obs;
  final RxString semesterAktif = "".obs;

  // Data Master Role & Tugas (Dari Firestore Pengaturan)
  final RxList<String> daftarRoleTersedia = <String>[].obs;
  final RxList<String> daftarTugasTersedia = <String>[].obs;
  final RxBool isRoleManagementLoading = false.obs;
  
  // Flag Mode Senyap (Penting untuk Windows saat Create User)
  final RxBool isCreatingNewUser = false.obs;

  // [BARU] Data Jenjang & Konfigurasi Hari Sekolah
  final RxString jenjangSekolah = "".obs; // Contoh: SD, SMP, SMA
  final RxList<String> hariSekolahAktif = <String>['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'].obs;

  // ===========================================================================
  // 3. LIFECYCLE
  // ===========================================================================

  @override
  void onInit() {
    super.onInit();
    
    // Listener: Bereaksi jika user login/logout
    ever(authC.userModel, (user) {
      if (user != null && user.idSekolah != null) {
        status.value = AppStatus.authenticated;
        _syncAllSchoolData();
      } else {
        status.value = AppStatus.unauthenticated;
      }
    });

    // Pemicu Awal: Jika saat aplikasi dibuka user sudah login
    if (authC.userModel.value != null) {
      status.value = AppStatus.authenticated;
      _syncAllSchoolData();
    }
  }

  // Wrapper untuk memanggil semua fungsi sync
  void _syncAllSchoolData() {
    _syncRoleManagementData();
    _syncTahunAjaranAktif();
    fetchSchoolData(); // Ambil Jenjang & Hari
  }

  Future<void> reloadRoleManagementData() async {
    await _syncRoleManagementData();
  }

  // ===========================================================================
  // 4. DATA FETCHING LOGIC
  // ===========================================================================

  // Ambil Daftar Role & Tugas dari Database
  Future<void> _syncRoleManagementData() async {
    if (idSekolah.isEmpty) return;
    try {
      isRoleManagementLoading.value = true;
      final doc = await _firestore.collection('Sekolah').doc(idSekolah).collection('pengaturan').doc('manajemen_peran').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        daftarRoleTersedia.assignAll(List<String>.from(data['daftar_role'] ?? []));
        daftarTugasTersedia.assignAll(List<String>.from(data['daftar_tugas'] ?? []));
      } else {
        // Default jika belum disetting
        daftarRoleTersedia.assignAll(['Kepala Sekolah', 'Guru Kelas', 'Guru Mapel', 'TU', 'Operator']);
        daftarTugasTersedia.assignAll(['Koordinator Kurikulum', 'Kesiswaan', 'Bendahara']);
      }
    } catch (e) {
      print("Gagal sync role: $e");
    } finally {
      isRoleManagementLoading.value = false;
    }
  }

  // Listener Real-time Tahun Ajaran
  void _syncTahunAjaranAktif() {
    if (idSekolah.isEmpty) return;
    _firestore.collection('Sekolah').doc(idSekolah)
        .collection('tahunajaran')
        .where('isAktif', isEqualTo: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        tahunAjaranAktif.value = doc.id;
        semesterAktif.value = doc.data()['semesterAktif']?.toString() ?? '1';
      } else {
        tahunAjaranAktif.value = "TIDAK DITEMUKAN";
      }
    });
  }

  // [BARU] Ambil Data Jenjang & Tentukan Hari Sekolah
  Future<void> fetchSchoolData() async {
    if (idSekolah.isEmpty) return;
    try {
      final doc = await _firestore.collection('Sekolah').doc(idSekolah).get();
      if (doc.exists) {
        final data = doc.data()!;
        
        // 1. Ambil Jenjang
        jenjangSekolah.value = data['jenjang'] ?? 'SD';

        // 2. [LOGIC BARU] Cek apakah ada pengaturan manual 'hariKerja'?
        if (data['hariKerja'] != null && (data['hariKerja'] as List).isNotEmpty) {
           // Jika sekolah sudah mengatur sendiri, pakai itu
           hariSekolahAktif.assignAll(List<String>.from(data['hariKerja']));
           print("📅 Config: Menggunakan Hari Kerja Custom sekolah.");
        } else {
           // Jika belum, gunakan Default berdasarkan Jenjang
           final String jenjangUpper = jenjangSekolah.value.toUpperCase();
           if (['SD', 'MI', 'TK', 'PAUD'].contains(jenjangUpper)) {
             hariSekolahAktif.assignAll(['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat']);
           } else {
             hariSekolahAktif.assignAll(['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu']);
           }
           print("📅 Config: Menggunakan Hari Kerja Default Jenjang.");
        }
        
        print("🏫 Data Sekolah Loaded. Hari Aktif: ${hariSekolahAktif.length} hari.");
      }
    } catch (e) {
      print("Error fetch school info: $e");
    }
  }
}