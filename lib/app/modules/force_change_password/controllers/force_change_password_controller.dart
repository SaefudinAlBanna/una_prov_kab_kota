import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';

class ForceChangePasswordController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authC = Get.find<AuthController>();

  final formKey = GlobalKey<FormState>();
  final newPassC = TextEditingController();
  final confirmPassC = TextEditingController();
  
  final isLoading = false.obs;
  final isNewPassObscure = true.obs;
  final isConfirmPassObscure = true.obs;

  @override
  void onClose() {
    newPassC.dispose();
    confirmPassC.dispose();
    super.onClose();
  }

  Future<void> changePassword() async {
    if (!formKey.currentState!.validate()) return;
    
    isLoading.value = true;
    print("🚀 [Step 1] Memulai Proses Ganti Password...");

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) throw "User sesi habis, silakan login ulang.";

      String email = currentUser.email!;
      String oldPassword = "pendidikan"; 
      String newPassword = newPassC.text;

      // --- LOGIC BARU: WINDOWS SAFE MODE ---
      try {
        print("🚀 [Step 2] Mencoba update password langsung...");
        await currentUser.updatePassword(newPassword);
        print("✅ [Step 2] Update password berhasil.");
      } catch (e) {
        print("⚠️ [Step 2] Gagal update langsung. Mencoba Re-Login (Safe Mode)...");
        
        // TRIK WINDOWS: Gunakan SignIn, BUKAN Reauthenticate
        // Ini me-refresh token tanpa memicu bug threading di plugin windows
        await _auth.signInWithEmailAndPassword(
          email: email, 
          password: oldPassword
        );
        
        // Ambil user object terbaru setelah login ulang
        currentUser = _auth.currentUser; 
        
        print("✅ [Step 2.5] Re-Login Berhasil. Update Password sekarang...");
        await currentUser!.updatePassword(newPassword);
        print("✅ [Step 2.5] Password berhasil diupdate.");
      }

      print("🚀 [Step 3] Update Flag di Firestore...");
      // Update data di users collection
      await _firestore.collection('users').doc(currentUser.uid).set({
        'mustChangePassword': false,
        'isProfileComplete': false, 
      }, SetOptions(merge: true));
      
      // Update juga di sub-collection pegawai sekolah (PENTING AGAR DATA KONSISTEN)
      // Kita cari idSekolah dari authController yang masih tersimpan
      String? idSekolah = _authC.userModel.value?.idSekolah;
      if (idSekolah != null) {
         await _firestore.collection('Sekolah').doc(idSekolah)
            .collection('pegawai').doc(currentUser.uid)
            .set({'mustChangePassword': false}, SetOptions(merge: true));
      }

      print("✅ [Step 3] Firestore Updated.");

      // --- FINISHING ---
      Get.snackbar("Sukses", "Password diperbarui! Melanjutkan...", 
        backgroundColor: Colors.green, colorText: Colors.white);

      isLoading.value = false; 

      // Delay sedikit agar Firestore sync
      await Future.delayed(Duration(seconds: 1));
      
      // Refresh User Data untuk memicu navigasi selanjutnya
      await _authC.loadUser();

    } on FirebaseAuthException catch (e) {
      print("❌ [Firebase Error] ${e.code}: ${e.message}");
      isLoading.value = false;
      String msg = "Gagal: ${e.message}";
      if (e.code == 'weak-password') msg = "Password terlalu lemah (min 6 karakter).";
      Get.snackbar("Gagal", msg, backgroundColor: Colors.red, colorText: Colors.white);
      
    } catch (e) {
      print("❌ [General Error] $e");
      isLoading.value = false;
      Get.snackbar("Error", "Terjadi kesalahan sistem: $e");
    }
  }
}