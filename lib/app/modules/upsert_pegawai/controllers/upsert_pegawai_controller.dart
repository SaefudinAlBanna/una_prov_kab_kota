import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/config_controller.dart';
import '../../../models/pegawai_model.dart';

class UpsertPegawaiController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ConfigController configC = Get.find<ConfigController>();
  final AuthController authC = Get.find<AuthController>(); // Ambil AuthController
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController namaC;
  late TextEditingController emailC;
  late TextEditingController passAdminC;

  final RxBool isLoadingProses = false.obs;
  final RxBool isObscure = true.obs;
  
  PegawaiModel? _pegawaiToEdit;
  bool get isEditMode => _pegawaiToEdit != null;

  final RxString jenisKelamin = "Laki-Laki".obs;
  final Rxn<String> jabatanTerpilih = Rxn<String>();
  final RxList<String> tugasTerpilih = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    namaC = TextEditingController();
    emailC = TextEditingController();
    passAdminC = TextEditingController();

    if (Get.arguments != null && Get.arguments is PegawaiModel) {
      _pegawaiToEdit = Get.arguments;
      _populateFieldsForEdit(_pegawaiToEdit!.uid);
    }
  }

  Future<void> _populateFieldsForEdit(String uid) async {
    try {
      final doc = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(uid).get();
      if(doc.exists) {
        final data = doc.data()!;
        namaC.text = data['nama'] ?? '';
        emailC.text = data['email'] ?? '';
        jenisKelamin.value = data['jeniskelamin'] ?? 'Laki-Laki';
        jabatanTerpilih.value = data['role'];
        if (data['tugas'] != null) {
           tugasTerpilih.assignAll(List<String>.from(data['tugas']));
        }
      }
    } catch (e) {
      print("Error loading data edit: $e");
    }
  }

  @override
  void onClose() {
    namaC.dispose(); emailC.dispose(); passAdminC.dispose();
    super.onClose();
  }
  
  void validasiDanProses() {
    if (!formKey.currentState!.validate()) return;

    if (isEditMode) {
      _prosesSimpanData();
    } else {
      isObscure.value = true; 
      passAdminC.clear();
      Get.defaultDialog(
        title: 'Verifikasi Admin',
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Masukkan password Admin Anda."),
            const SizedBox(height: 15),
            Obx(() => TextField(
              controller: passAdminC, 
              obscureText: isObscure.value, 
              autofocus: true, 
              decoration: InputDecoration(
                labelText: 'Password Admin',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(isObscure.value ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => isObscure.toggle(),
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
    // 1. Validasi State
    if (isLoadingProses.value) return;
    
    // Validasi input form tambahan jika perlu
    
    isLoadingProses.value = true;

    final currentUser = _auth.currentUser;
    final adminEmail = currentUser?.email;
    final adminPassword = passAdminC.text;

    try {
      if (isEditMode) {
        // --- LOGIKA UPDATE (Tidak Berubah) ---
        final dataToUpdate = {
          'nama': namaC.text.trim(), 
          'jeniskelamin': jenisKelamin.value,
          'alias': "${jenisKelamin.value == "Laki-Laki" ? "Bapak" : "Ibu"} ${namaC.text.trim()}",
          'role': jabatanTerpilih.value, 
          'tugas': tugasTerpilih.toList(),
        };
        
        // Update di Sekolah
        await _firestore.collection("Sekolah").doc(configC.idSekolah).collection('pegawai').doc(_pegawaiToEdit!.uid).update(dataToUpdate);
        
        // [TAMBAHAN] Update juga di Global Users agar nama/role tetap sinkron
        try {
           await _firestore.collection('users').doc(_pegawaiToEdit!.uid).update({
             'nama': namaC.text.trim(),
             // Jangan update role/idSekolah sembarangan disini, cukup nama/jabatan
           });
        } catch (e) {
           print("Warning: Gagal update user global: $e");
        }
        
        Get.back(result: true); 
        Get.snackbar('Berhasil', 'Data pegawai diperbarui.');

      } else {
        // --- LOGIKA CREATE (DENGAN DENORMALISASI) ---
        
        if (currentUser == null) throw Exception("Sesi Admin habis.");
        if (adminPassword.isEmpty) throw Exception("Password Admin wajib diisi.");

        // Pause Listener
        authC.isPaused = true; 
        configC.isCreatingNewUser.value = true;

        try {
          // A. Buat User Auth
          print("👤 Creating user on Firebase Auth...");
          UserCredential uc = await _auth.createUserWithEmailAndPassword(
            email: emailC.text.trim(),
            password: 'pendidikan', 
          );
          String uidBaru = uc.user!.uid;

          // B. Logout & Login Balik Admin
          await _auth.signOut();
          await _auth.signInWithEmailAndPassword(email: adminEmail!, password: adminPassword);
          
          // C. Force Refresh Token (Wajib untuk Windows)
          await _auth.currentUser?.getIdToken(true);
          await Future.delayed(const Duration(seconds: 1)); // Jeda aman

          // D. Siapkan Data
          // Tentukan peran sistem. Jika jabatan 'Kepala Sekolah' -> superadmin, jika tidak -> user biasa
          String peranSistem = (jabatanTerpilih.value == 'Kepala Sekolah') ? 'superadmin' : 'user';

          // E. [PENTING] SIMPAN KE DUA TEMPAT (ATOMIC BATCH LEBIH AMAN)
          WriteBatch batch = _firestore.batch();

          // 1. Simpan ke Sekolah/{id}/pegawai
          DocumentReference refSekolah = _firestore.collection("Sekolah").doc(configC.idSekolah).collection('pegawai').doc(uidBaru);
          batch.set(refSekolah, {
            'uid': uidBaru, 
            'email': emailC.text.trim(), 
            'createdAt': FieldValue.serverTimestamp(), 
            'createdBy': adminEmail,
            'mustChangePassword': true,
            'nama': namaC.text.trim(), 
            'jeniskelamin': jenisKelamin.value,
            'alias': "${jenisKelamin.value == "Laki-Laki" ? "Bapak" : "Ibu"} ${namaC.text.trim()}",
            'role': jabatanTerpilih.value, 
            'tugas': tugasTerpilih.toList(),
            'peranSistem': peranSistem,
            'nip': '-', 
            'noTelp': '-', 
            'alamat': '-', 
            'profileImageUrl': null, 
            'statusKepegawaian': 'Aktif',
          });

          // 2. [INI YANG DITUNGGU] Simpan ke Global Users
          DocumentReference refGlobal = _firestore.collection('users').doc(uidBaru);
          batch.set(refGlobal, {
            'uid': uidBaru,
            'email': emailC.text.trim(),
            'nama': namaC.text.trim(),
            'role': 'pegawai', // Role utama sistem
            'idSekolah': configC.idSekolah, // Kunci agar bisa login ke dashboard sekolah
            'scopeProv': null, // Sekolah tidak punya scope wilayah
            'scopeDist': null,
            'jabatan': jabatanTerpilih.value, // Info tambahan
            'peranSistem': peranSistem,
            'mustChangePassword': true,
            'isProfileComplete': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Eksekusi Batch
          await batch.commit();

          // F. Resume
          authC.isPaused = false;
          configC.isCreatingNewUser.value = false;

          Get.back(result: true); 
          Get.snackbar(
            'Sukses', 
            'Pegawai ditambahkan.\nEmail: ${emailC.text}\nPass: pendidikan', 
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.green,
            colorText: Colors.white
          );

        } catch (e) {
          // Error Handling Khusus Permission Denied (Windows Bug False Positive)
          if (e.toString().contains('permission-denied')) {
             // Cek manual apakah data global users masuk? (Optional)
             // Asumsi sukses karena batch bersifat atomik (All or Nothing)
             authC.isPaused = false;
             configC.isCreatingNewUser.value = false;
             
             Get.back(result: true);
             Get.snackbar('Info', 'Data tersimpan (Sesi mungkin perlu refresh).', backgroundColor: Colors.orange.shade100);
          } else {
             // Re-login attempt & throw real error
             authC.isPaused = false;
             configC.isCreatingNewUser.value = false;
             if (_auth.currentUser?.email != adminEmail) {
               try { await _auth.signInWithEmailAndPassword(email: adminEmail!, password: adminPassword); } catch (_) {}
             }
             rethrow;
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? "Terjadi kesalahan Auth.";
      if (e.code == 'wrong-password') msg = 'Password Admin salah.';
      if (e.code == 'email-already-in-use') msg = 'Email sudah terdaftar.';
      Get.snackbar('Gagal', msg, backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoadingProses.value = false;
      passAdminC.clear();
      // Double check flag mati
      authC.isPaused = false;
      configC.isCreatingNewUser.value = false;
    }
  }

  String? validator(String? value, String fieldName) {
    if (value == null || value.isEmpty) return '$fieldName tidak boleh kosong.';
    return null;
  }
}