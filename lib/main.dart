import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/bindings/initial_binding.dart'; // <-- Import file baru tadi
import 'app/routes/app_pages.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await GetStorage.init();

  // HAPUS BAGIAN INI (Penyebab Error):
  // Get.put(AuthController(), permanent: true); 
  // Get.put(StorageController(), permanent: true);

  runApp(
    GetMaterialApp(
      title: "Sistem Pendidikan Terpadu",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      
      // TAMBAHKAN INI (SOLUSINYA):
      initialBinding: InitialBinding(),
      
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    ),
  );
}