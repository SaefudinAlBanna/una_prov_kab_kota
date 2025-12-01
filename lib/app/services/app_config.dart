import 'package:get/get.dart';

class AppConfig extends GetxService {
  // Singleton Pattern
  static AppConfig get to => Get.find();

  // Konfigurasi Default (Nanti di-override oleh Flavor)
  RxString appName = "Una Digital School".obs;
  RxString logoAsset = "assets/logo_default.png".obs;
  
  // Feature Flags (Saklar Fitur)
  bool enableDeepLearning = true;
  bool enableAkreditasiData = true; // Fitur andalan dinas
  
  // Fungsi Init (Panggil di main.dart nanti)
  Future<AppConfig> init() async {
    // Di sini nanti logika Flavor dimuat
    return this;
  }
}