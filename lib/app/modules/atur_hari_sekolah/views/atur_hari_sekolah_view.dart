import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/atur_hari_sekolah_controller.dart';

class AturHariSekolahView extends GetView<AturHariSekolahController> {
  const AturHariSekolahView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Atur Hari Aktif Sekolah")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(child: Text("Pengaturan ini akan mempengaruhi tampilan Jadwal Pelajaran, Jurnal, dan Absensi.", style: TextStyle(fontSize: 12))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text("Pilih Hari Masuk:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Expanded(
              child: Card(
                child: ListView.builder(
                  itemCount: controller.semuaHari.length,
                  itemBuilder: (context, index) {
                    final hari = controller.semuaHari[index];
                    return Obx(() => CheckboxListTile(
                      title: Text(hari),
                      value: controller.selectedHari.contains(hari),
                      activeColor: Colors.green,
                      onChanged: (val) => controller.toggleHari(hari, val),
                    ));
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.simpanPerubahan,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: Text(controller.isLoading.value ? "MENYIMPAN..." : "SIMPAN PENGATURAN", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )),
            ),
          ],
        ),
      ),
    );
  }
}