import 'package:get/get.dart';

// Import Controller Dashboard (Induk)
import '../controllers/dashboard_controller.dart';

// IMPORT CONTROLLER SEKOLAH (ANAK) - Pastikan path import ini benar
import '../../sekolah/controllers/school_dashboard_controller.dart'; 
// Atau jika folder sekolah ada di modules, sesuaikan path importnya misal:
// import '../../school_dashboard/controllers/school_dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Controller untuk Halaman Utama (Navigasi & Role)
    Get.lazyPut<DashboardController>(
      () => DashboardController(),
    );

    // 2. [INI YANG WAJIB DITAMBAHKAN]
    // Controller untuk Tampilan Sekolah yang ada di dalam Dashboard
    Get.lazyPut<SchoolDashboardController>(
      () => SchoolDashboardController(),
    );
  }
}


// import 'package:get/get.dart';
// import '../controllers/dashboard_controller.dart';

// class DashboardBinding extends Bindings {
//   @override
//   void dependencies() {
//     Get.lazyPut<DashboardController>(
//       () => DashboardController(),
//     );
//   }
// }