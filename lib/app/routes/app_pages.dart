import 'package:get/get.dart';

import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/force_change_password/bindings/force_change_password_binding.dart';
import '../modules/force_change_password/views/force_change_password_view.dart';
import '../modules/force_complete_profile/bindings/force_complete_profile_binding.dart';
import '../modules/force_complete_profile/views/force_complete_profile_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/tahun_ajaran/bindings/tahun_ajaran_binding.dart';
import '../modules/tahun_ajaran/views/tahun_ajaran_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.DASHBOARD,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: _Paths.FORCE_CHANGE_PASSWORD,
      page: () => ForceChangePasswordView(),
      binding: ForceChangePasswordBinding(),
    ),
    GetPage(
      name: _Paths.FORCE_COMPLETE_PROFILE,
      page: () => ForceCompleteProfileView(),
      binding: ForceCompleteProfileBinding(),
    ),
    GetPage(
      name: _Paths.TAHUN_AJARAN,
      page: () => TahunAjaranView(),
      binding: TahunAjaranBinding(),
    ),
  ];
}
