import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import 'items/dashboard_dinas_view.dart';
import 'items/dashboard_sekolah_view.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Logic Switching: Role Dinas vs Sekolah
      if (controller.isDinas) {
        return DashboardDinasView();
      } else {
        return const DashboardSekolahView();
      }
    });
  }
}