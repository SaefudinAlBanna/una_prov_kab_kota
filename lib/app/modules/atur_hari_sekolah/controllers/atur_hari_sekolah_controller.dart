import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart';

class AturHariSekolahController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxBool isLoading = false.obs;
  
  // Semua kemungkinan hari
  final List<String> semuaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  
  // Hari yang dipilih user
  final RxList<String> selectedHari = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Load settingan saat ini dari ConfigController
    selectedHari.assignAll(configC.hariSekolahAktif);
  }

  void toggleHari(String hari, bool? value) {
    if (value == true) {
      if (!selectedHari.contains(hari)) selectedHari.add(hari);
    } else {
      if (selectedHari.contains(hari)) selectedHari.remove(hari);
    }
  }

  Future<void> simpanPerubahan() async {
    if (selectedHari.isEmpty) {
      Get.snackbar("Gagal", "Minimal pilih 1 hari aktif.");
      return;
    }

    isLoading.value = true;
    try {
      // 1. Urutkan hari sesuai standar (Senin -> Minggu)
      selectedHari.sort((a, b) => semuaHari.indexOf(a).compareTo(semuaHari.indexOf(b)));

      // 2. Simpan ke Firestore
      await _firestore.collection('Sekolah').doc(configC.idSekolah).update({
        'hariKerja': selectedHari.toList(),
      });

      // 3. [PERBAIKAN] Reload Config Global (Wajib Panggil Ini!)
      await configC.fetchSchoolData();
      
      Get.back();
      Get.snackbar("Berhasil", "Hari aktif sekolah telah diperbarui.");
      
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan: $e");
      // print("Gagal menyimpan hari aktif sekolah: $e");
    } finally {
      isLoading.value = false;
    }
  }
}