import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/config_controller.dart';
import '../controllers/storage_controller.dart';
import '../services/app_config.dart';
// import '../controllers/config_controller.dart'; // Nanti jika dipakai

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Masukkan semua Controller Global di sini
    Get.put(AuthController(), permanent: true);
    Get.put(ConfigController(), permanent: true);
    Get.put(StorageController(), permanent: true);
    Get.put(AppConfig(), permanent: true);
  }
}