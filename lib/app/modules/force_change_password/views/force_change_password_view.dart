import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/force_change_password_controller.dart';

class ForceChangePasswordView extends StatelessWidget {
  // Inject Controller langsung di sini (Lazy Put)
  final controller = Get.put(ForceChangePasswordController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Form(
                key: controller.formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_reset, size: 64, color: Colors.blue[800]),
                    SizedBox(height: 16),
                    Text("Amankan Akun Anda", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("Password default tidak aman. Silakan buat password baru sebelum melanjutkan.", 
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                    SizedBox(height: 32),

                    // Password Baru
                    Obx(() => TextFormField(
                      controller: controller.newPassC,
                      obscureText: controller.isNewPassObscure.value,
                      decoration: InputDecoration(
                        labelText: "Password Baru",
                        prefixIcon: Icon(Icons.vpn_key),
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(controller.isNewPassObscure.value ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => controller.isNewPassObscure.toggle(),
                        ),
                      ),
                      validator: (val) => (val!.length < 6) ? "Minimal 6 karakter" : null,
                    )),
                    SizedBox(height: 16),

                    // Konfirmasi Password
                    Obx(() => TextFormField(
                      controller: controller.confirmPassC,
                      obscureText: controller.isConfirmPassObscure.value,
                      decoration: InputDecoration(
                        labelText: "Ulangi Password",
                        prefixIcon: Icon(Icons.check_circle_outline),
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(controller.isConfirmPassObscure.value ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => controller.isConfirmPassObscure.toggle(),
                        ),
                      ),
                      validator: (val) => (val != controller.newPassC.text) ? "Password tidak sama" : null,
                    )),
                    SizedBox(height: 32),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Obx(() => ElevatedButton(
                        onPressed: controller.isLoading.value ? null : controller.changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: controller.isLoading.value 
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text("SIMPAN PASSWORD BARU", style: TextStyle(fontWeight: FontWeight.bold)),
                      )),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}