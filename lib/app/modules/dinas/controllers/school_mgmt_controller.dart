import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // Penting
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../models/school_model.dart';

class SchoolMgmtController extends GetxController {
  final AuthController authC = Get.find<AuthController>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  RxList<SchoolModel> schools = <SchoolModel>[].obs;
  RxBool isLoading = false.obs;

  RxList<String> kecamatanList = <String>[].obs;
  RxString selectedKecamatan = RxString('Semua');
  RxString selectedJenjang = RxString('Semua');
  RxString selectedStatus = RxString('Semua'); 

  // List Kabupaten (Sekarang Dinamis)
  RxList<String> districtList = <String>[].obs;
  RxString selectedDistrictFilter = ''.obs; // Hapus ? agar tidak null safety issue ribet
  
  // Statistik
  RxInt totalSekolah = 0.obs;
  RxInt totalSiswaEstimasi = 0.obs;

  // Getter: List Sekolah yang sudah difilter
  List<SchoolModel> get filteredSchools {
    return schools.where((s) {
      // 1. Cek Kecamatan
      bool passKec = selectedKecamatan.value == 'Semua' || s.kecamatan == selectedKecamatan.value;
      // 2. Cek Jenjang
      bool passJenjang = selectedJenjang.value == 'Semua' || s.jenjang == selectedJenjang.value;
      // 3. [BARU] Cek Status
      bool passStatus = selectedStatus.value == 'Semua' || s.status == selectedStatus.value;
      
      return passKec && passJenjang && passStatus;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    // Tunggu data user siap, baru init
    if (authC.userModel.value == null) {
      authC.loadUser().then((_) => _decideInitialLoad());
    } else {
      _decideInitialLoad();
    }
  }

  void _decideInitialLoad() {
    String? role = authC.userModel.value?.role;
    
    if (role == 'dinas_prov') {
      // Jika Provinsi, tarik daftar kabupaten dari user yang terdaftar
      fetchDistrictsFromUsers();
    } else if (role == 'dinas_kab') {
      // Jika Kabupaten, langsung tarik sekolah
      loadSchools();
    }
  }

  // --- [BARU] TARIK DAFTAR KABUPATEN DARI FIRESTORE ---
  Future<void> fetchDistrictsFromUsers() async {
    try {
      isLoading.value = true;
      String? myProv = authC.userModel.value?.scopeProv;

      // Logic: Cari user yang role='dinas_kab' DAN scopeProv sama dengan saya
      QuerySnapshot qs = await firestore.collection('users')
          .where('role', isEqualTo: 'dinas_kab')
          .where('scopeProv', isEqualTo: myProv)
          .get();

      // Ambil field scopeDist dan masukkan ke list (Set agar unik)
      Set<String> districts = {};
      for (var doc in qs.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['scopeDist'] != null) {
          districts.add(data['scopeDist']);
        }
      }
      
      districtList.value = districts.toList()..sort();
      print("✅ BERHASIL LOAD KABUPATEN: ${districtList.length} ditemukan");

    } catch (e) {
      print("❌ Error fetch districts: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadSchools({String? districtFilter}) async {
    isLoading.value = true;
    if (districtFilter != null) selectedDistrictFilter.value = districtFilter;

    try {
      if (authC.userModel.value == null) await authC.loadUser();

      String? userRole = authC.userModel.value?.role;
      String? scopeProv = authC.userModel.value?.scopeProv;
      String? scopeDist = authC.userModel.value?.scopeDist;

      Query collection = firestore.collection('Sekolah');

      if (userRole == 'dinas_prov') {
        if (selectedDistrictFilter.value.isNotEmpty) {
           collection = collection.where('districtId', isEqualTo: selectedDistrictFilter.value);
        } else {
           collection = collection.where('provinceId', isEqualTo: scopeProv);
        }
      } else if (userRole == 'dinas_kab') {
        collection = collection.where('districtId', isEqualTo: scopeDist);
      }

      QuerySnapshot qs = await collection.get(); 
      schools.value = qs.docs.map((doc) => SchoolModel.fromJson(doc.data() as Map<String, dynamic>, doc.id)).toList();
      
      // [BARU] POPULATE LIST KECAMATAN UNIK
      Set<String> uniqueKec = {'Semua'}; // Default option
      for (var s in schools) {
        if (s.kecamatan != null && s.kecamatan!.isNotEmpty) {
          uniqueKec.add(s.kecamatan!);
        }
      }
      kecamatanList.value = uniqueKec.toList()..sort();
      
      // Reset filter saat ganti wilayah
      selectedKecamatan.value = 'Semua';
      selectedJenjang.value = 'Semua';
      selectedStatus.value = 'Semua';

      // Update Statistik
      totalSekolah.value = schools.length;
      totalSiswaEstimasi.value = schools.length * 150; 

    } catch (e) {
      print("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addSchool(
      String nama, 
      String npsn, 
      String alamat, 
      String jenjang, 
      String kecamatan, 
      String status, 
      String emailAdmin, // Parameter Baru
      String namaAdmin,  // Parameter Baru
      {String? targetDistrictId}
  ) async {
    Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);

    try {
       // 1. SIAPKAN DATA WILAYAH
       String? myProv = authC.userModel.value?.scopeProv;
       String? myDist = authC.userModel.value?.scopeDist;
       String role = authC.userModel.value!.role;
       String finalDistId = (role == 'dinas_kab') ? myDist! : targetDistrictId!;

       // 2. BUAT DOKUMEN SEKOLAH DI FIRESTORE
       DocumentReference schoolRef = await firestore.collection('Sekolah').add({
        'npsn': npsn,
        'nama': nama,
        'alamat': alamat,
        'provinceId': myProv ?? '',
        'districtId': finalDistId,
        'jenjang': jenjang,
        'kecamatan': kecamatan,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'emailAdmin': emailAdmin, // Simpan info email admin
      });

      // 3. [BARU] BUAT AKUN LOGIN ADMIN SEKOLAH (AUTO)
      await _createSchoolAdminAccount(
        email: emailAdmin, 
        nama: namaAdmin, 
        schoolId: schoolRef.id, 
        prov: myProv ?? '',
        dist: finalDistId
      );
      
      Get.back(); // Tutup loading
      Get.back(); // Tutup form
      Get.snackbar("Sukses", "Sekolah & Akun Admin ($emailAdmin) berhasil dibuat!", 
        backgroundColor: Colors.green[100], duration: Duration(seconds: 4));
      
      loadSchools(); 

    } catch (e) {
      if(Get.isDialogOpen!) Get.back();
      print("ERROR ADD SCHOOL: $e");
      Get.snackbar("Gagal", e.toString(), backgroundColor: Colors.red[100]);
    }
  }

  Future<void> _createSchoolAdminAccount({
    required String email, 
    required String nama, 
    required String schoolId,
    required String prov,
    required String dist
  }) async {
    FirebaseApp? secondaryApp;
    try {
      print("⚙️ Membuat akun admin sekolah: $email");
      
      // 1. Inisialisasi App Kedua (Agar admin dinas tidak ter-logout)
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      // 2. Create User di Auth menggunakan App Kedua
      UserCredential uc = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: email, password: "pendidikan");
      
      String uid = uc.user!.uid;

      // 3. Simpan Data User di Firestore (Collection 'users') - Pakai instance utama
      await firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'nama': nama,
        'role': 'pegawai',
        'fotoUrl': null,
        'idSekolah': schoolId,
        'scopeProv': prov,
        'scopeDist': dist,
        
        // FLAG KEAMANAN
        'mustChangePassword': true, // Wajib ganti pass
        'isProfileComplete': false, // Wajib lengkapi profil (NIP, NoHP, dll)
        
        'createdAt': FieldValue.serverTimestamp(),
        'jabatan': 'Administrator Sekolah', 
        'peranSistem': 'admin_sekolah' 
      });

      // 4. Simpan Data Pegawai di Sub-Collection Sekolah (PENTING UNTUK RULES)
      await firestore.collection('Sekolah').doc(schoolId).collection('pegawai').doc(uid).set({
        'uid': uid,
        'nama': nama,
        'email': email,
        'role': 'Kepala Sekolah', // Default role di sekolah
        'fotoUrl': null,
        'peranSistem': 'superadmin', // Superadmin di sekolah ini
        'statusKepegawaian': 'Aktif',
        'nip': '-',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("✅ Akun Admin Sekolah Berhasil Dibuat: $uid");

    } catch (e) {
      print("❌ Gagal membuat user auth: $e");
      throw "Gagal membuat akun login: $e";
    } finally {
      // 5. Hapus App Kedua agar tidak memakan memori
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }
}