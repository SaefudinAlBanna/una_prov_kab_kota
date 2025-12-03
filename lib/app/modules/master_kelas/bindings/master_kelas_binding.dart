import 'package:get/get.dart';

import '../controllers/master_kelas_controller.dart';

class MasterKelasBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MasterKelasController>(
      () => MasterKelasController(),
    );
  }
}
