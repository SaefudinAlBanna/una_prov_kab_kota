import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/app_config.dart'; // Import config

class DashboardController extends GetxController {
  final AuthController authC = Get.find<AuthController>();

  // Logic Cek Role (Gatekeeper)
  bool get isDinas {
    final role = authC.userModel.value?.role;
    return role == 'dinas_prov' || role == 'dinas_kab';
  }

  bool get isSekolah {
    final role = authC.userModel.value?.role;
    return role == 'pegawai'; 
  }

  bool get isWaliMurid {
    final role = authC.userModel.value?.role;
    return role == 'wali_murid';
  }

  // Greeting Message (Tetap dipertahankan)
  String get greeting {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }
}