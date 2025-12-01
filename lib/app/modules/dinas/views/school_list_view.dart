import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/school_model.dart';
import '../controllers/school_mgmt_controller.dart';

class SchoolListView extends StatelessWidget {
  final SchoolMgmtController controller = Get.find<SchoolMgmtController>();
  final bool isReadOnly;

  SchoolListView({this.isReadOnly = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. HEADER (Sama seperti sebelumnya)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Obx(() => Text(
                  controller.selectedDistrictFilter.value.isNotEmpty 
                    ? "${controller.selectedDistrictFilter.value}"
                    : "Data Sekolah", 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                )),
              ),
              if (!isReadOnly)
                ElevatedButton.icon(
                  onPressed: () => _showAddDialog(context),
                  icon: Icon(Icons.add, size: 18),
                  label: Text("Tambah"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
                )
            ],
          ),
        ),

        // 2. FILTER SECTION (Kecamatan, Jenjang, Status)
        Container(
          color: Colors.white,
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A. Filter Kecamatan
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Obx(() => Row(
                  children: controller.kecamatanList.map((kec) => _buildFilterChip(
                    label: kec, 
                    isSelected: controller.selectedKecamatan.value == kec,
                    onSelected: (val) => val ? controller.selectedKecamatan.value = kec : null
                  )).toList(),
                )),
              ),
              SizedBox(height: 8),
              
              // B. Filter Jenjang & Status (Satu Baris agar hemat tempat, atau dipisah)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Jenjang
                    Obx(() => Row(
                      children: ['Semua', 'SD', 'PKBM', 'SMP', 'SMA', 'SMK', 'SLB'].map((jenjang) => _buildFilterChip(
                        label: jenjang,
                        isSelected: controller.selectedJenjang.value == jenjang,
                        color: Colors.orange,
                        onSelected: (val) => val ? controller.selectedJenjang.value = jenjang : null
                      )).toList(),
                    )),
                    // Separator visual
                    Container(height: 20, width: 1, color: Colors.grey[300], margin: EdgeInsets.symmetric(horizontal: 10)),
                    // Status (Negeri/Swasta)
                    Obx(() => Row(
                      children: ['Semua', 'Negeri', 'Swasta'].map((status) => _buildFilterChip(
                        label: status,
                        isSelected: controller.selectedStatus.value == status,
                        color: Colors.green,
                        onSelected: (val) => val ? controller.selectedStatus.value = status : null
                      )).toList(),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),

        Divider(height: 1),

        // 3. LIST DATA
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => await controller.loadSchools(),
            child: Obx(() {
              if (controller.isLoading.value) return Center(child: CircularProgressIndicator());
              
              final listData = controller.filteredSchools; // Pakai Getter baru

              if (listData.isEmpty) {
                return ListView(children: [SizedBox(height: 50), Center(child: Text("Data tidak ditemukan."))]);
              }
              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: listData.length,
                itemBuilder: (context, index) => _buildSchoolCard(listData[index]),
              );
            }),
          ),
        ),

        // 4. [BARU] FOOTER COUNTER DINAMIS
        Obx(() {
          int count = controller.filteredSchools.length;
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.blue[900],
              boxShadow: [BoxShadow(color: Colors.black12, offset: Offset(0, -2), blurRadius: 4)]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Menampilkan data terpilih:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text("$count Sekolah", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required Function(bool) onSelected, MaterialColor color = Colors.blue}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: color[100],
        backgroundColor: Colors.grey[100],
        labelStyle: TextStyle(
          color: isSelected ? color[900] : Colors.grey[700], 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12
        ),
        onSelected: onSelected,
        visualDensity: VisualDensity.compact, // Agar tidak terlalu gemuk
        showCheckmark: false,
      ),
    );
  }

  Widget _buildSchoolCard(SchoolModel sekolah) {
    Color badgeColor = sekolah.status == 'Negeri' ? Colors.green : Colors.purple;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey[200]!)),
      color: Colors.white,
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          child: Text(sekolah.jenjang ?? 'S', style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        title: Row(
          children: [
            Expanded(child: Text(sekolah.nama, style: TextStyle(fontWeight: FontWeight.bold))),
            if (sekolah.status != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(sekolah.status!, style: TextStyle(fontSize: 10, color: badgeColor, fontWeight: FontWeight.bold)),
              )
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text("NPSN: ${sekolah.npsn} • ${sekolah.kecamatan ?? '-'}", style: TextStyle(fontSize: 12, color: Colors.black87)),
            Text(sekolah.alamat, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      ),
    );
  }


  void _showAddDialog(BuildContext context) {
    // Controller Existing
    final npsnC = TextEditingController();
    final namaC = TextEditingController();
    final alamatC = TextEditingController();
    final kecamatanC = TextEditingController(); 
    final districtC = TextEditingController(); 
    
    // Controller Baru (Untuk Akun)
    final emailAdminC = TextEditingController();
    final namaAdminC = TextEditingController();

    String selectedJenjang = 'SD';
    String selectedStatus = 'Negeri';
    bool isProv = controller.authC.userModel.value?.role == 'dinas_prov';

    Get.defaultDialog(
      title: "Tambah Sekolah & Akun Admin",
      radius: 10,
      contentPadding: EdgeInsets.all(20),
      content: SingleChildScrollView( // Scrollable agar tidak overflow
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Data Sekolah", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
            SizedBox(height: 10),
            TextField(controller: npsnC, decoration: InputDecoration(labelText: "NPSN", border: OutlineInputBorder(), isDense: true)),
            SizedBox(height: 10),
            TextField(controller: namaC, decoration: InputDecoration(labelText: "Nama Sekolah", border: OutlineInputBorder(), isDense: true)),
            SizedBox(height: 10),
            TextField(controller: alamatC, decoration: InputDecoration(labelText: "Alamat Jalan", border: OutlineInputBorder(), isDense: true)),
            SizedBox(height: 10),
            TextField(controller: kecamatanC, decoration: InputDecoration(labelText: "Kecamatan", border: OutlineInputBorder(), isDense: true)),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedJenjang,
                    items: ['SD', 'PKBM', 'SMP', 'SMA', 'SMK', 'SLB'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => selectedJenjang = v!,
                    decoration: InputDecoration(labelText: "Jenjang", border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    items: ['Negeri', 'Swasta'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => selectedStatus = v!,
                    decoration: InputDecoration(labelText: "Status", border: OutlineInputBorder(), isDense: true),
                  ),
                ),
              ],
            ),
            
            if (isProv) ...[
              SizedBox(height: 10),
              TextField(controller: districtC, decoration: InputDecoration(labelText: "Kabupaten/Kota", border: OutlineInputBorder(), isDense: true)),
            ],

            SizedBox(height: 20),
            Divider(thickness: 2),
            Text("Akun Kepala Sekolah / TU", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[900])),
            SizedBox(height: 5),
            Text("Password Default: pendidikan", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
            SizedBox(height: 10),
            
            TextField(controller: namaAdminC, decoration: InputDecoration(labelText: "Nama Admin/Kepsek", border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.person))),
            SizedBox(height: 10),
            TextField(controller: emailAdminC, decoration: InputDecoration(labelText: "Email Login", border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.email))),
          ],
        ),
      ),
      textConfirm: "Simpan & Buat Akun",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      buttonColor: Colors.blue[800],
      onConfirm: () {
        // Validasi Sederhana
        if (emailAdminC.text.isEmpty || namaC.text.isEmpty) {
          Get.snackbar("Error", "Nama Sekolah dan Email Admin wajib diisi");
          return;
        }

        controller.addSchool(
          namaC.text, npsnC.text, alamatC.text, selectedJenjang, kecamatanC.text, selectedStatus,
          emailAdminC.text, // Param baru
          namaAdminC.text,  // Param baru
          targetDistrictId: isProv ? districtC.text : null
        );
      }
    );
  }
}