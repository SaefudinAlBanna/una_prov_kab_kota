import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/master_kelas_controller.dart';

class MasterKelasView extends GetView<MasterKelasController> {
  const MasterKelasView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Master Data Kelas")),
      body: Obx(() {
        if(controller.isLoading.value) return Center(child: CircularProgressIndicator());
        if(controller.listMasterKelas.isEmpty) return Center(child: Text("Belum ada master kelas."));
        
        return ListView.builder(
          itemCount: controller.listMasterKelas.length,
          itemBuilder: (ctx, i) {
             var data = controller.listMasterKelas[i];
             return ListTile(
               leading: CircleAvatar(child: Text("${data['urutan']~/10}")),
               title: Text(data['namaKelas'], style: TextStyle(fontWeight: FontWeight.bold)),
               subtitle: Text("Fase: ${data['fase']}"),
               trailing: IconButton(
                 icon: Icon(Icons.delete, color: Colors.red),
                 onPressed: () => controller.hapusMaster(data['id']),
               ),
             );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: controller.showFormTambah,
      ),
    );
  }
}