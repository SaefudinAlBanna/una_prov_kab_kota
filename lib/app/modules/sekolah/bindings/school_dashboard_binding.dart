import 'package:get/get.dart';
// Jangan lupa import controller sekolahnya
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../sekolah/controllers/school_dashboard_controller.dart'; 

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Controller Utama Dashboard
    Get.lazyPut<DashboardController>(
      () => DashboardController(),
    );

    // [TAMBAHAN WAJIB] Suntikkan Controller Sekolah disini juga
    // Agar saat DashboardView memanggil SchoolDashboardView, controllernya sudah siap.
    Get.lazyPut<SchoolDashboardController>(
      () => SchoolDashboardController(),
    );
  }
}