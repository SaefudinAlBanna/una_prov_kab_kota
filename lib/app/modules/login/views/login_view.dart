import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDesktop = context.width > 800;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Row(
          children: [
            // BAGIAN KIRI (Desktop Only)
            if (isDesktop)
              Expanded(
                flex: 6,
                child: Container(
                  color: Colors.blue[900],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [ // Tambahkan const biar performa lebih baik
                      Icon(Icons.school, size: 100, color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        "Sistem Pendidikan Terpadu",
                        style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Provinsi & Kabupaten/Kota",
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),

            // BAGIAN KANAN (Form Login)
            Expanded(
              flex: 4,
              child: Container(
                color: Colors.white,
                // [FIX 3] Tambahkan Center agar form tetap ditengah jika layar tinggi
                child: Center( 
                  // [FIX 4] Tambahkan SingleChildScrollView agar tidak Overflow saat layar pendek/keyboard muncul
                  child: SingleChildScrollView( 
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Selamat Datang", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                        const SizedBox(height: 10),
                        const Text("Silakan masuk untuk mengakses dashboard.", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 40),
                        
                        TextField(
                          controller: controller.emailC,
                          decoration: InputDecoration(
                            labelText: "Email Pengguna",
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        Obx(() => TextField(
                          controller: controller.passC,
                          obscureText: controller.isObscure.value,
                          decoration: InputDecoration(
                            labelText: "Kata Sandi",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(controller.isObscure.value ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => controller.isObscure.toggle(),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        )),
                        const SizedBox(height: 30),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: Obx(() => ElevatedButton(
                            onPressed: controller.isLoading.value ? null : () => controller.login(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[900],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: controller.isLoading.value
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("MASUK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          )),
                        ),
                        
                        const SizedBox(height: 20),
                        Center(
                          child: Text("Ver 1.0.0 - Una Digital", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}