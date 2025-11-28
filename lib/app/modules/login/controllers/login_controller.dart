import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';

class LoginController extends GetxController {
  final AuthController authC = Get.find<AuthController>();

  // [FIX 1] Langsung inisialisasi di sini, jangan pakai 'late'
  // Ini membuat controller baru setiap kali LoginController dibuat
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();
  
  final RxBool isObscure = true.obs;
  
  RxBool get isLoading => authC.isLoading;

  @override
  void onInit() {
    super.onInit();
    // Tidak perlu inisialisasi emailC/passC disini lagi
  }

  // [FIX 2] HAPUS method onClose(). 
  // Kita biarkan TextEditingController mati secara alami saat class ini dihapus dari memori
  // untuk menghindari error "used after disposed" saat animasi transisi.
  /* 
  @override
  void onClose() {
    emailC.dispose();
    passC.dispose();
    super.onClose();
  }
  */

  void login() {
    if (emailC.text.isNotEmpty && passC.text.isNotEmpty) {
      authC.login(emailC.text, passC.text);
    } else {
      Get.snackbar("Error", "Email dan Password wajib diisi", 
        snackPosition: SnackPosition.BOTTOM, 
        backgroundColor: Colors.orange, colorText: Colors.white);
    }
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../controllers/auth_controller.dart';

// class LoginController extends GetxController {
//   // Panggil AuthController Utama
//   final AuthController authC = Get.find<AuthController>();

//   late TextEditingController emailC;
//   late TextEditingController passC;
  
//   final RxBool isObscure = true.obs;
  
//   // Mengambil status loading dari AuthController
//   RxBool get isLoading => authC.isLoading;

//   @override
//   void onInit() {
//     super.onInit();
//     emailC = TextEditingController();
//     passC = TextEditingController();
//   }

//   @override
//   void onClose() {
//     emailC.dispose();
//     passC.dispose();
//     super.onClose();
//   }

//   void login() {
//     if (emailC.text.isNotEmpty && passC.text.isNotEmpty) {
//       authC.login(emailC.text, passC.text);
//     } else {
//       Get.snackbar("Error", "Email dan Password wajib diisi", 
//         snackPosition: SnackPosition.BOTTOM, 
//         backgroundColor: Colors.orange, colorText: Colors.white);
//     }
//   }
// }