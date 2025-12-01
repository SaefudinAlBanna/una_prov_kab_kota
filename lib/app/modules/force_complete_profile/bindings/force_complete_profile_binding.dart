import 'package:get/get.dart';

import '../controllers/force_complete_profile_controller.dart';

class ForceCompleteProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForceCompleteProfileController>(
      () => ForceCompleteProfileController(),
    );
  }
}
