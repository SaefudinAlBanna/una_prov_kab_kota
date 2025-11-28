import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';

class DashboardController extends GetxController {
  // Instance AuthController
  final AuthController authC = Get.find<AuthController>();

  // Logic cek Role
  bool get isDinas {
    String role = authC.userModel.value?.role ?? ''; 
    return role == 'dinas_prov' || role == 'dinas_kab';
  }

  bool get isSekolah {
    String role = authC.userModel.value?.role ?? '';
    return role == 'pegawai'; 
  }

  // Greeting Message
  String get greeting {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }
}