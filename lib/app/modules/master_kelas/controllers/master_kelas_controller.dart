import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/config_controller.dart'; // Sesuaikan path

class MasterKelasController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<Map<String, dynamic>> listMasterKelas = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  // Jenjang sekolah (diambil dari config/sekolah jika ada, atau default)
  // Nanti bisa diambil dari configC.infoSekolah['jenjang']
  final List<String> opsiFase = ['A (Kelas 1-2)', 'B (Kelas 3-4)', 'C (Kelas 5-6)', 'D (SMP)', 'E (SMA X)', 'F (SMA XI-XII)'];
  final List<String> opsiTingkat = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', 'TK-A', 'TK-B', 'KB'];

  @override
  void onInit() {
    super.onInit();
    fetchMasterKelas();
  }

  Future<void> fetchMasterKelas() async {
    isLoading.value = true;
    try {
      final snap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('master_kelas').orderBy('urutan').get();
      listMasterKelas.assignAll(snap.docs.map((e) => {
        'id': e.id,
        ...e.data()
      }).toList());
    } catch (e) {
      Get.snackbar("Error", "Gagal load master kelas: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void showFormTambah() {
    String selectedTingkat = '1';
    String selectedFase = 'A (Kelas 1-2)';
    TextEditingController suffixC = TextEditingController(); // Contoh: "A", "B", "Abu Bakar"

    Get.defaultDialog(
      title: "Tambah Master Kelas",
      content: Column(
        children: [
          DropdownButtonFormField<String>(
            value: selectedTingkat,
            items: opsiTingkat.map((e) => DropdownMenuItem(value: e, child: Text("Kelas $e"))).toList(),
            onChanged: (v) => selectedTingkat = v!,
            decoration: InputDecoration(labelText: "Tingkat"),
          ),
          SizedBox(height: 10),
          TextField(
            controller: suffixC,
            decoration: InputDecoration(
              labelText: "Nama Paralel (Suffix)", 
              hintText: "Contoh: A, B, atau Unggulan",
              border: OutlineInputBorder()
            ),
          ),
          SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedFase,
            items: opsiFase.map((e) => DropdownMenuItem(value: e, child: Text("Fase $e"))).toList(),
            onChanged: (v) => selectedFase = v!,
            decoration: InputDecoration(labelText: "Fase Kurikulum"),
          ),
        ],
      ),
      textConfirm: "Simpan",
      textCancel: "Batal",
      onConfirm: () {
        // Gabungkan Nama: "1" + "A" = "1A"
        String suffix = suffixC.text.trim().toUpperCase();
        String namaFinal = suffix.isEmpty ? selectedTingkat : "$selectedTingkat$suffix";
        // Logic urutan sederhana (Tingkat * 10)
        int urutan = 0;
        try { urutan = int.parse(selectedTingkat.replaceAll(RegExp(r'[^0-9]'), '')) * 10; } catch(e) {}
        
        _simpanMasterKelas(namaFinal, selectedFase.split(' ')[0], urutan);
        Get.back();
      }
    );
  }

  Future<void> _simpanMasterKelas(String nama, String fase, int urutan) async {
    try {
      await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('master_kelas').add({
        'namaKelas': nama,
        'fase': fase,
        'urutan': urutan,
      });
      fetchMasterKelas();
      Get.snackbar("Sukses", "Master Kelas $nama ditambahkan");
    } catch (e) {
      Get.snackbar("Gagal", "$e");
    }
  }
  
  void hapusMaster(String id) {
     Get.defaultDialog(
       title: "Hapus?",
       middleText: "Kelas ini akan hilang dari pilihan menu buat kelas.",
       textConfirm: "Ya, Hapus",
       onConfirm: () async {
         await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('master_kelas').doc(id).delete();
         Get.back();
         fetchMasterKelas();
       }
     );
  }
}