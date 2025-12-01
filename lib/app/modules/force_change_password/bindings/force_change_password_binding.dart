import 'package:get/get.dart';

import '../controllers/force_change_password_controller.dart';

class ForceChangePasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForceChangePasswordController>(
      () => ForceChangePasswordController(),
    );
  }
}
