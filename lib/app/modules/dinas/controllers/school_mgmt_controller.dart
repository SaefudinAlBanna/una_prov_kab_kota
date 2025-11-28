import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> addSchool(String nama, String npsn, String alamat, String jenjang, String kecamatan, String status, 
    {String? targetDistrictId}) async {

    Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);

    try {
      String? myProv = authC.userModel.value?.scopeProv;
       String? myDist = authC.userModel.value?.scopeDist;
       String role = authC.userModel.value!.role;
       String finalDistId = (role == 'dinas_kab') ? myDist! : targetDistrictId!;

       SchoolModel newSchool = SchoolModel(
        npsn: npsn,
        nama: nama,
        alamat: alamat,
        provinceId: myProv ?? '',
        districtId: finalDistId,
        jenjang: jenjang,
        kecamatan: kecamatan, // Baru
        status: status,       // Baru (Negeri/Swasta)
        createdAt: DateTime.now(),
      );
      
      await firestore.collection('Sekolah').add(newSchool.toJson());
      
      Get.back(); Get.back();
      Get.snackbar("Berhasil", "Sekolah ditambahkan");
      loadSchools(); 
    } catch (e) {
      if(Get.isDialogOpen!) Get.back();
      Get.snackbar("Error", e.toString(), 
      backgroundColor: Colors.red[100]);
    }
  }
}