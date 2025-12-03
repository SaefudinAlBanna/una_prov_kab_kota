import 'package:get/get.dart';

import '../modules/atur_hari_sekolah/bindings/atur_hari_sekolah_binding.dart';
import '../modules/atur_hari_sekolah/views/atur_hari_sekolah_view.dart';
import '../modules/daftar_siswa/bindings/daftar_siswa_binding.dart';
import '../modules/daftar_siswa/views/daftar_siswa_view.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/editor_jadwal/bindings/editor_jadwal_binding.dart';
import '../modules/editor_jadwal/views/editor_jadwal_view.dart';
import '../modules/force_change_password/bindings/force_change_password_binding.dart';
import '../modules/force_change_password/views/force_change_password_view.dart';
import '../modules/force_complete_profile/bindings/force_complete_profile_binding.dart';
import '../modules/force_complete_profile/views/force_complete_profile_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/import_siswa/bindings/import_siswa_binding.dart';
import '../modules/import_siswa/views/import_siswa_view.dart';
import '../modules/jadwal_pelajaran/bindings/jadwal_pelajaran_binding.dart';
import '../modules/jadwal_pelajaran/views/jadwal_pelajaran_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/manajemen_peran/bindings/manajemen_peran_binding.dart';
import '../modules/manajemen_peran/views/manajemen_peran_view.dart';
import '../modules/master_jam/bindings/master_jam_binding.dart';
import '../modules/master_jam/views/master_jam_view.dart';
import '../modules/master_kelas/bindings/master_kelas_binding.dart';
import '../modules/master_kelas/views/master_kelas_view.dart';
import '../modules/master_mapel/bindings/master_mapel_binding.dart';
import '../modules/master_mapel/views/master_mapel_view.dart';
import '../modules/pegawai/bindings/pegawai_binding.dart';
import '../modules/pegawai/views/pegawai_view.dart';
import '../modules/pemberian_kelas_siswa/bindings/pemberian_kelas_siswa_binding.dart';
import '../modules/pemberian_kelas_siswa/views/pemberian_kelas_siswa_view.dart';
import '../modules/penugasan_guru/bindings/penugasan_guru_binding.dart';
import '../modules/penugasan_guru/views/penugasan_guru_view.dart';
import '../modules/tahun_ajaran/bindings/tahun_ajaran_binding.dart';
import '../modules/tahun_ajaran/views/tahun_ajaran_view.dart';
import '../modules/upsert_pegawai/bindings/upsert_pegawai_binding.dart';
import '../modules/upsert_pegawai/views/upsert_pegawai_view.dart';
import '../modules/upsert_siswa/bindings/upsert_siswa_binding.dart';
import '../modules/upsert_siswa/views/upsert_siswa_view.dart';

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
    GetPage(
      name: _Paths.PEGAWAI,
      page: () => const PegawaiView(),
      binding: PegawaiBinding(),
    ),
    GetPage(
      name: _Paths.UPSERT_PEGAWAI,
      page: () => const UpsertPegawaiView(),
      binding: UpsertPegawaiBinding(),
    ),
    GetPage(
      name: _Paths.MANAJEMEN_PERAN,
      page: () => const ManajemenPeranView(),
      binding: ManajemenPeranBinding(),
    ),
    GetPage(
      name: _Paths.MASTER_KELAS,
      page: () => const MasterKelasView(),
      binding: MasterKelasBinding(),
    ),
    GetPage(
      name: _Paths.PEMBERIAN_KELAS_SISWA,
      page: () => const PemberianKelasSiswaView(),
      binding: PemberianKelasSiswaBinding(),
    ),
    GetPage(
      name: _Paths.DAFTAR_SISWA,
      page: () => const DaftarSiswaView(),
      binding: DaftarSiswaBinding(),
    ),
    GetPage(
      name: _Paths.UPSERT_SISWA,
      page: () => const UpsertSiswaView(),
      binding: UpsertSiswaBinding(),
    ),
    GetPage(
      name: _Paths.IMPORT_SISWA,
      page: () => const ImportSiswaView(),
      binding: ImportSiswaBinding(),
    ),
    GetPage(
      name: _Paths.JADWAL_PELAJARAN,
      page: () => const JadwalPelajaranView(),
      binding: JadwalPelajaranBinding(),
    ),
    GetPage(
      name: _Paths.MASTER_MAPEL,
      page: () => const MasterMapelView(),
      binding: MasterMapelBinding(),
    ),
    GetPage(
      name: _Paths.MASTER_JAM,
      page: () => const MasterJamView(),
      binding: MasterJamBinding(),
    ),
    GetPage(
      name: _Paths.PENUGASAN_GURU,
      page: () => const PenugasanGuruView(),
      binding: PenugasanGuruBinding(),
    ),
    GetPage(
      name: _Paths.EDITOR_JADWAL,
      page: () => const EditorJadwalView(),
      binding: EditorJadwalBinding(),
    ),
    GetPage(
      name: _Paths.ATUR_HARI_SEKOLAH,
      page: () => const AturHariSekolahView(),
      binding: AturHariSekolahBinding(),
    ),
  ];
}
