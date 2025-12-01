import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../models/carousel_item_model.dart';
import '../controllers/school_dashboard_controller.dart';

class SchoolDashboardView extends GetView<SchoolDashboardController> {
  // Inject controller jika belum ada (misal direct access tanpa binding)
  // SchoolDashboardController get controller => Get.put(SchoolDashboardController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.loadSchoolData();
          await controller.fetchCarouselData();
        },
        child: CustomScrollView(
          slivers: [
            // 1. HEADER SLIVER (Profil & Background)
            SliverAppBar(
              expandedHeight: 200.0, floating: false, pinned: true,
              backgroundColor: Colors.indigo.shade800,
              actions: [
                IconButton(icon: Icon(Icons.logout), onPressed: () => controller.authC.logout())
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Ganti dengan aset background Anda jika ada
                    Container(color: Colors.indigo), 
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.6), Colors.transparent], 
                          begin: Alignment.topCenter, end: Alignment.bottomCenter
                        )
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 60.0, bottom: 20.0),
                      child: SingleChildScrollView(
                        
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // FOTO PROFIL
                            Obx(() {
                              String? url = controller.authC.userModel.value?.fotoUrl;
                              String nama = controller.authC.userModel.value?.nama ?? "User";
                              return CircleAvatar(
                                radius: 40, backgroundColor: Colors.white24,
                                child: CircleAvatar(
                                  radius: 36,
                                  backgroundImage: (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
                                  backgroundColor: Colors.white,
                                  child: (url == null || url.isEmpty) 
                                    ? Text(nama[0], style: TextStyle(fontSize: 30, color: Colors.indigo)) 
                                    : null,
                                ),
                              );
                            }),
                            const SizedBox(height: 10),
                            // NAMA & ROLE
                            Obx(() => Text(
                              controller.authC.userModel.value?.nama ?? "Memuat...",
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            )),
                            Obx(() => Text(
                              "${controller.namaSekolah.value}",
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. QUICK ACCESS MENU
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 20, 16.0, 10), 
                child: Text("Menu Utama", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: Obx(() => SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 10.0, mainAxisSpacing: 10.0, childAspectRatio: 0.85,
                ),
                delegate: SliverChildListDelegate(
                  controller.quickAccessMenus.map((menu) => _buildMenuItem(
                    imagePath: menu['image'], 
                    title: menu['title'],
                    onTap: menu.containsKey('route') ? () => Get.toNamed(menu['route']) : menu['onTap'],
                  )).toList(),
                ),
              )),
            ),

            // 3. CAROUSEL INFO
            SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Obx(() {
                if (controller.isCarouselLoading.value) {
                  return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
                }
                return CarouselSlider.builder(
                  itemCount: controller.daftarCarousel.length,
                  itemBuilder: (context, index, realIndex) {
                    final item = controller.daftarCarousel[index];
                    return _buildCarouselCard(item);
                  },
                  options: CarouselOptions(
                    height: 150, autoPlay: controller.daftarCarousel.length > 1,
                    enlargeCenterPage: true, viewportFraction: 0.9, aspectRatio: 16 / 9,
                  ),
                );
              }),
            ),

            // 4. INFO LIST
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text("Informasi Sekolah", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            _buildInformasiList(),
            
            SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildMenuItem({required String imagePath, required String title, VoidCallback? onTap}) {
    // Karena aset belum dipindah, kita pakai fallback Icon jika image gagal load
    // Atau user bisa ganti logika ini nanti
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sementara pakai Icon statis jika gambar blm ada, atau Image.asset dengan errorBuilder
            Image.asset(
              'assets/png/$imagePath', // Pastikan folder assets/png ada
              width: 32, height: 32,
              errorBuilder: (ctx, err, stack) => Icon(Icons.grid_view, color: Colors.indigo, size: 32),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselCard(CarouselItemModel item) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [item.warna.withOpacity(0.9), item.warna], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: item.warna.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                    child: Text(item.judul.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 8),
                  Text(item.isi, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if(item.subJudul != null) Text(item.subJudul!, style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            Icon(item.ikon, color: Colors.white.withOpacity(0.3), size: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildInformasiList() {
    return Obx(() {
      if (controller.daftarInfoSekolah.isEmpty) {
        return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Belum ada informasi terbaru."))));
      }
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final doc = controller.daftarInfoSekolah[index];
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as Timestamp?;
            final tanggal = timestamp?.toDate() ?? DateTime.now();
            
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 1,
              child: ListTile(
                leading: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.newspaper, color: Colors.grey), // Ganti CachedNetworkImage nanti jika ada URL
                ),
                title: Text(data['judul'] ?? 'Info', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['isi'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 4),
                    Text(timeago.format(tanggal, locale: 'id'), style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
          childCount: controller.daftarInfoSekolah.length,
        ),
      );
    });
  }
}




// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../services/app_config.dart';
// import '../controllers/school_dashboard_controller.dart';

// class SchoolDashboardView extends StatelessWidget {
//   // Inject Controller secara manual karena kita manual routing dari Dashboard utama
//   final SchoolDashboardController controller = Get.put(SchoolDashboardController());

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: Obx(() => Text(AppConfig.to.appName.value)), // Dari Config
//         backgroundColor: Colors.indigo,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.notifications),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: Icon(Icons.logout),
//             onPressed: () => controller.authC.logout(),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 1. Header Sekolah
//             _buildSchoolHeader(),
            
//             SizedBox(height: 20),
            
//             // 2. Deep Learning Status (Joyful Metric)
//             _buildJoyfulMetricCard(),

//             SizedBox(height: 20),
//             Text("Menu Utama", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             SizedBox(height: 10),

//             // 3. Grid Menu
//             GridView.count(
//               shrinkWrap: true,
//               physics: NeverScrollableScrollPhysics(),
//               crossAxisCount: 2,
//               crossAxisSpacing: 15,
//               mainAxisSpacing: 15,
//               childAspectRatio: 1.3,
//               children: [
//                 _buildMenuCard(
//                   title: "Akademik (KBM)",
//                   icon: Icons.class_,
//                   color: Colors.blue,
//                   onTap: () => controller.toDeepLearningJournal(),
//                   subtitle: "Jurnal & Absensi",
//                 ),
//                 _buildMenuCard(
//                   title: "Kesiswaan",
//                   icon: Icons.people,
//                   color: Colors.orange,
//                   onTap: () {},
//                   subtitle: "8 Dimensi Profil",
//                 ),
//                 _buildMenuCard(
//                   title: "Kepegawaian",
//                   icon: Icons.work,
//                   color: Colors.teal,
//                   onTap: () {},
//                   subtitle: "Data Guru & Tendik",
//                 ),
//                 _buildMenuCard(
//                   title: "Akreditasi",
//                   icon: Icons.verified_user,
//                   color: Colors.purple,
//                   onTap: () => controller.toAkreditasi(),
//                   subtitle: "Instrumen Data",
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSchoolHeader() {
//     return Container(
//       padding: EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: Colors.indigo[50],
//             child: Icon(Icons.school, size: 30, color: Colors.indigo),
//           ),
//           SizedBox(width: 15),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Obx(() => Text(
//                   controller.namaSekolah.value,
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 )),
//                 Obx(() => Text(
//                   "NPSN: ${controller.npsn.value}",
//                   style: TextStyle(color: Colors.grey[600]),
//                 )),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildJoyfulMetricCard() {
//     return Container(
//       padding: EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(colors: [Colors.pink[400]!, Colors.pink[600]!]),
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text("Indeks Joyful Learning", style: TextStyle(color: Colors.white70, fontSize: 12)),
//               Text("😄 4.5/5.0", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
//               Text("Mood Siswa Pekan Ini: Bahagia", style: TextStyle(color: Colors.white, fontSize: 12)),
//             ],
//           ),
//           Icon(Icons.sentiment_very_satisfied, color: Colors.white.withOpacity(0.3), size: 50),
//         ],
//       ),
//     );
//   }

//   Widget _buildMenuCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.all(15),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(15),
//           border: Border.all(color: Colors.grey[200]!),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: EdgeInsets.all(10),
//               decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
//               child: Icon(icon, color: color, size: 24),
//             ),
//             Spacer(),
//             Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//             Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 11)),
//           ],
//         ),
//       ),
//     );
//   }
// }