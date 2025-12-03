// lib/app/modules/editor_jadwal/views/editor_jadwal_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/editor_jadwal_controller.dart';

class EditorJadwalView extends GetView<EditorJadwalController> {
  const EditorJadwalView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Jadwal Pelajaran'),
        actions: [
          Obx(() => controller.isSaving.value
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
              : IconButton(icon: const Icon(Icons.save), onPressed: controller.simpanJadwal)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedKelasId.value,
              hint: const Text('Pilih Kelas'),
              items: controller.daftarKelas.map((k) => DropdownMenuItem<String>(value: k['id'], child: Text(k['nama']))).toList(),
              onChanged: controller.onKelasChanged,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            )),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.selectedKelasId.value == null) return const Expanded(child: Center(child: Text('Pilih kelas untuk memulai.')));
              if (controller.isLoadingJadwal.value) return const Expanded(child: Center(child: CircularProgressIndicator()));
              return Expanded(child: _buildScheduleEditor());
            }),
          ],
        ),
      ),
      floatingActionButton: Obx(() => controller.selectedKelasId.value != null && !controller.isLoadingJadwal.value
          ? FloatingActionButton(onPressed: controller.tambahPelajaran, child: const Icon(Icons.add))
          : const SizedBox.shrink()),
    );
  }

  // Widget _buildScheduleEditor() {
  //   return Column(children: [
  //     DropdownButtonFormField<String>(
  //       value: controller.selectedHari.value,
  //       items: controller.daftarHari.map((h) => DropdownMenuItem<String>(value: h, child: Text(h))).toList(),
  //       onChanged: (v) => controller.selectedHari.value = v!,
  //       decoration: const InputDecoration(border: OutlineInputBorder()),
  //     ),
  //     const SizedBox(height: 16),
  //     Expanded(child: Obx(() {
  //       final listPelajaran = controller.jadwalPelajaran[controller.selectedHari.value]!;
  //       if (listPelajaran.isEmpty) return const Center(child: Text('Jadwal kosong. Klik + untuk menambah.'));
  //       listPelajaran.sort((a,b) => (a['jamMulai'] as String? ?? 'Z').compareTo((b['jamMulai'] as String? ?? 'Z')));
        
  //       return ListView.builder(
  //         itemCount: listPelajaran.length,
  //         itemBuilder: (context, index) => _buildPelajaranCard(listPelajaran[index], index),
  //       );
  //     })),
  //   ]);
  // }

  Widget _buildScheduleEditor() {
    return Column(children: [
      // [PERBAIKAN] Bungkus dengan Obx agar reaktif terhadap perubahan jumlah hari
      Obx(() => DropdownButtonFormField<String>(
        value: controller.selectedHari.value,
        // Gunakan daftarHari yang sekarang reaktif
        items: controller.daftarHari.map((h) => DropdownMenuItem<String>(value: h, child: Text(h))).toList(),
        onChanged: (v) {
             if (v != null) controller.selectedHari.value = v;
        },
        decoration: const InputDecoration(border: OutlineInputBorder()),
      )),
      const SizedBox(height: 16),
      Expanded(child: Obx(() {
        final listPelajaran = controller.jadwalPelajaran[controller.selectedHari.value]!;
        if (listPelajaran.isEmpty) return const Center(child: Text('Jadwal kosong. Klik + untuk menambah.'));
        listPelajaran.sort((a,b) => (a['jamMulai'] as String? ?? 'Z').compareTo((b['jamMulai'] as String? ?? 'Z')));
        
        return ListView.builder(
          itemCount: listPelajaran.length,
          itemBuilder: (context, index) => _buildPelajaranCard(listPelajaran[index], index),
        );
      })),
    ]);
  }

  // [PEROMBAKAN TOTAL WIDGET INI]
  Widget _buildPelajaranCard(Map<String, dynamic> pelajaran, int index) {
    final bool isKegiatanUmum = pelajaran['idMapel'] == null && pelajaran['namaMapel'] != null;

    return Card(
      color: isKegiatanUmum ? Colors.blue.shade50 : null,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Bagian Header (Hapus & Judul) ---
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                isKegiatanUmum ? pelajaran['namaMapel'] : 'Slot Pelajaran',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isKegiatanUmum ? Colors.blue.shade800 : null,
                ),
              ),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => controller.hapusPelajaran(index)),
            ]),
            const SizedBox(height: 12),

            // --- Bagian Jam ---
            Row(children: [
              Expanded(child: _buildTimePickerField(Get.context!, 'Jam Mulai', pelajaran['jamMulai'], () => controller.pilihWaktu(Get.context!, index, true))),
              const SizedBox(width: 8),
              Expanded(child: _buildTimePickerField(Get.context!, 'Jam Selesai', pelajaran['jamSelesai'], () => controller.pilihWaktu(Get.context!, index, false))),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.widgets_outlined, color: Colors.blue.shade800),
                onPressed: () => controller.pilihDariTemplate(index),
                tooltip: "Pilih dari Template",
              )
            ]),
            const SizedBox(height: 12),

            // --- Bagian Konten Utama ---
            if (isKegiatanUmum)
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.blue),
                title: Text(pelajaran['namaMapel'] ?? ''),
                subtitle: const Text("Kegiatan Sekolah"),
              )
            else
              Column(
                children: [
                  // Dropdown Mapel (Tidak perlu Obx, karena trigger rebuild dari parent)
                  DropdownButtonFormField<String>(
                    value: pelajaran['idMapel'],
                    hint: const Text("Pilih Mata Pelajaran"),
                    isExpanded: true,
                    items: controller.daftarMapelTersedia.map((m) => DropdownMenuItem<String>(value: m['idMapel'], child: Text(m['nama']))).toList(),
                    onChanged: (v) => controller.updatePelajaran(index, 'idMapel', v),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  // [PERBAIKAN LOGIKA DI SINI]
                  // Pengecekan kondisi dilakukan di LUAR Obx.
                  if (pelajaran['idMapel'] == 'halaqah') 
                     // Jika Halaqah: Tampilkan Widget Statis (Tanpa Obx)
                     ListTile(
                        leading: const Icon(Icons.group_work_outlined),
                        title: Text(pelajaran['namaGuru'] ?? 'Tim Tahsin/Tahfidz'),
                        subtitle: const Text("Guru Halaqah"),
                      )
                  else 
                     // Jika Mapel Biasa: Tampilkan Widget Reaktif (Dengan Obx)
                     // Karena bagian ini butuh mendengar perubahan 'tampilkanSemuaGuru'
                     Obx(() => Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: pelajaran['idGuru'],
                            hint: const Text("Pilih Guru Pengajar"),
                            isExpanded: true,
                            // Filter guru berdasarkan toggle
                            items: controller.guruDropdownList.where((g) {
                              if (controller.tampilkanSemuaGuru.value) return true;
                              return g['idMapel'] == pelajaran['idMapel'];
                            }).map((g) => DropdownMenuItem<String>(value: g['uid'], child: Text(g['alias']))).toList(),
                            onChanged: (v) => controller.updatePelajaran(index, 'idGuru', v),
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          ),
                          SwitchListTile(
                            title: const Text("Tampilkan semua guru", style: TextStyle(fontSize: 14)),
                            value: controller.tampilkanSemuaGuru.value,
                            onChanged: controller.toggleTampilkanSemuaGuru,
                            dense: true,
                          ),
                        ],
                      )),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk input waktu
  Widget _buildTimePickerField(BuildContext context, String label, String? time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: Text(time ?? 'Pilih Waktu', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}