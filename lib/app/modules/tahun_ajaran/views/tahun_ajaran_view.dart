import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/tahun_ajaran_controller.dart';

class TahunAjaranView extends GetView<TahunAjaranController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tahun Ajaran & Semester'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.listTahunAjaran.isEmpty) {
          return Center(child: Text("Belum ada data tahun ajaran"));
        }
        return ListView.builder(
          itemCount: controller.listTahunAjaran.length,
          padding: EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final data = controller.listTahunAjaran[index];
            return Card(
              color: data.isAktif ? Colors.green.shade50 : Colors.white,
              elevation: 2,
              margin: EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  "${data.nama}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text("Semester: ${data.semesterAktif}"),
                trailing: Switch(
                  value: data.isAktif, // [UBAH] Sesuaikan dengan nama variabel di Model baru
                  activeColor: Colors.green,
                  onChanged: (val) {
                     if (val) controller.setTahunAktif(data.id!);
                  },
                ),
                onLongPress: () {
                   if(!data.isAktif) controller.deleteTahun(data.id!); // [UBAH]
                },
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        label: Text("Tahun Baru"),
        icon: Icon(Icons.add),
      ),
    );
  }

  // Dialog sederhana untuk input
  void _showAddDialog(BuildContext context) {
    controller.namaC.text = ""; // Reset
    controller.semesterSelected.value = "1"; // Reset
    
    Get.defaultDialog(
      title: "Tambah Tahun Ajaran",
      content: Column(
        children: [
          TextField(
            controller: controller.namaC,
            decoration: InputDecoration(
              labelText: "Tahun (Cth: 2024/2025)",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          Obx(() => DropdownButtonFormField<String>(
            value: controller.semesterSelected.value,
            items: ["1", "2"]
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => controller.semesterSelected.value = val!,
            decoration: InputDecoration(
              labelText: "Semester",
              border: OutlineInputBorder(),
            ),
          )),
        ],
      ),
      textConfirm: "Simpan",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () {
        controller.tambahTahunAjaran();
      },
    );
  }
}