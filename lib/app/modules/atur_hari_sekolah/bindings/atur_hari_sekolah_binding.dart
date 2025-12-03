import 'package:get/get.dart';

import '../controllers/atur_hari_sekolah_controller.dart';

class AturHariSekolahBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AturHariSekolahController>(
      () => AturHariSekolahController(),
    );
  }
}
