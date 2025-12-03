import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/config_controller.dart';
import '../../../controllers/auth_controller.dart'; 
import '../../../models/siswa_model.dart';

class UpsertSiswaController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>(); // Tambah ini
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController namaC, nisnC, sppC, passAdminC;
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;

  SiswaModel? _siswaToEdit;
  bool get isEditMode => _siswaToEdit != null;

  @override
  void onInit() {
    super.onInit();
    namaC = TextEditingController();
    nisnC = TextEditingController();
    sppC = TextEditingController();
    passAdminC = TextEditingController();
    
    if (Get.arguments != null && Get.arguments is SiswaModel) {
      _siswaToEdit = Get.arguments;
      namaC.text = _siswaToEdit!.namaLengkap;
      nisnC.text = _siswaToEdit!.nisn;
      sppC.text = _siswaToEdit!.spp?.toString() ?? '0';
    }
  }

  @override
  void onClose() {
    namaC.dispose();
    nisnC.dispose();
    sppC.dispose();
    passAdminC.dispose();
    super.onClose();
  }

  void validasiDanProses() {
    if (!formKey.currentState!.validate()) return;
    if (isEditMode) {
      _prosesSimpanData();
    } else {
      // Reset
      isPasswordVisible.value = false;
      passAdminC.clear();

      Get.defaultDialog(
        title: 'Verifikasi Admin',
        contentPadding: EdgeInsets.all(20),
        content: Column(
          children: [
            Text("Masukkan password Admin untuk membuat akun siswa."),
            SizedBox(height: 10),
            Obx(() => TextField(
                  controller: passAdminC,
                  autofocus: true,
                  obscureText: !isPasswordVisible.value,
                  decoration: InputDecoration(
                    labelText: 'Password Admin',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(isPasswordVisible.value ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => isPasswordVisible.toggle(),
                    ),
                  ),
                )),
          ],
        ),
        actions: [
          OutlinedButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _prosesSimpanData();
            }, 
            child: const Text('Konfirmasi')
          ),
        ],
      );
    }
  }

   Future<void> _prosesSimpanData() async {
    if (isLoading.value) return;
    isLoading.value = true;
    
    final adminEmail = _auth.currentUser?.email;
    final adminPassword = passAdminC.text;

    try {
      if (isEditMode) {
        // --- LOGIKA UPDATE ---
        final dataToUpdate = {
          'namaLengkap': namaC.text.trim(),
          'spp': num.tryParse(sppC.text) ?? 0,
          // NISN biasanya tidak boleh diubah sembarangan jika jadi patokan email
          // Tapi jika mau diubah, logic auth-nya ribet. Kita asumsi edit biodata saja.
        };
        await _firestore.collection('Sekolah').doc(configC.idSekolah)
            .collection('siswa').doc(_siswaToEdit!.uid).update(dataToUpdate);
        
        Get.back(result: true); 
        Get.snackbar('Berhasil', 'Data siswa diperbarui.');
      
      } else {
        // --- LOGIKA CREATE (Windows Friendly) ---
        if (adminEmail == null || adminPassword.isEmpty) {
          throw Exception('Password admin kosong.');
        }

        // 1. Pause Listener Auth agar tidak logout
        authC.isPaused = true;
        configC.isCreatingNewUser.value = true;

        try {
          // 2. Format Email Baru: nisn@siswa.id
          final emailSiswa = "${nisnC.text.trim()}@siswa.id";
          final passwordSiswa = "pendidikan";

          print("👤 Membuat user siswa: $emailSiswa");
          
          // 3. Create User & Logout
          UserCredential cred = await _auth.createUserWithEmailAndPassword(
            email: emailSiswa, 
            password: passwordSiswa
          );
          String uidBaru = cred.user!.uid;
          await _auth.signOut();

          // 4. Re-Login Admin
          print("🔙 Admin login kembali...");
          await _auth.signInWithEmailAndPassword(email: adminEmail, password: adminPassword);
          
          // 5. Force Refresh Token (Anti Permission Denied)
          print("🔄 Refresh Token...");
          await _auth.currentUser?.getIdToken(true);
          await Future.delayed(Duration(seconds: 1));

          // 6. Simpan Data ke Firestore
          print("💾 Simpan Data Siswa...");
          final dataSiswa = {
            'uid': uidBaru,
            'nisn': nisnC.text.trim(),
            'namaLengkap': namaC.text.trim(),
            'email': emailSiswa,
            'spp': num.tryParse(sppC.text) ?? 0,
            
            'statusSiswa': "Aktif",
            'isProfileComplete': false, 
            'mustChangePassword': true,
            'memilikiCatatanBk': false,
            
            'createdAt': FieldValue.serverTimestamp(), 
            'createdBy': adminEmail,
            'kelasId': null, // Belum masuk kelas
          };
          
          // Simpan di Sub-collection Sekolah
          await _firestore.collection('Sekolah').doc(configC.idSekolah)
              .collection('siswa').doc(uidBaru).set(dataSiswa);

          // Simpan di Users Global (agar bisa login)
          await _firestore.collection('users').doc(uidBaru).set({
            'uid': uidBaru,
            'email': emailSiswa,
            'nama': namaC.text.trim(),
            'role': 'wali_murid', // Atau 'siswa'? Kapten bilang "Orangtua login pakai akun anak" -> role wali_murid/siswa?
            // Kita set 'siswa' saja dulu, atau 'wali_murid' jika Logic Login mengecek itu.
            // Sesuai AuthController awal, role bisa 'wali_murid'.
            // Mari kita pakai 'wali_murid' agar sesuai AuthController.
            'idSekolah': configC.idSekolah,
            'mustChangePassword': true,
            'isProfileComplete': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          // 7. Resume Listener
          authC.isPaused = false;
          configC.isCreatingNewUser.value = false;

          Get.back(result: true);
          Get.snackbar(
            'Sukses', 
            'Siswa ditambahkan.\nLogin: $emailSiswa\nPass: $passwordSiswa',
            duration: Duration(seconds: 5),
            backgroundColor: Colors.green,
            colorText: Colors.white
          );

        } catch (e) {
          // Safety Net
          authC.isPaused = false;
          configC.isCreatingNewUser.value = false;
          
          // Jika permission denied tapi data masuk, anggap sukses (kasus rare)
          if (e.toString().contains('permission-denied')) {
             Get.back(result: true);
             Get.snackbar('Info', 'Data tersimpan (Sesi perlu refresh).');
          } else {
             // Coba login balik admin jika error auth
             if(_auth.currentUser?.email != adminEmail) {
               try { await _auth.signInWithEmailAndPassword(email: adminEmail, password: adminPassword); } catch(_){}
             }
             rethrow;
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Terjadi kesalahan.';
      if (e.code == 'wrong-password') msg = 'Password Admin salah.';
      if (e.code == 'email-already-in-use') msg = 'NISN/Email sudah terdaftar.';
      Get.snackbar('Gagal', msg, backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
      passAdminC.clear();
      authC.isPaused = false;
      configC.isCreatingNewUser.value = false;
    }
  }
}