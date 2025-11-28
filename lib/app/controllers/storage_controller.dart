import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart'; // Pastikan di pubspec ada

class StorageController extends GetxController {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload Foto Profil ke Firebase Storage
  /// Path: profiles/{uid}.jpg
  Future<String?> uploadProfilePicture(File file, String uid) async {
    try {
      // 1. Buat Referensi (Folder: profiles)
      final Reference ref = _storage.ref().child('profiles').child('$uid.jpg');
      
      // 2. Metadata (Cache Control agar cepat load)
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': file.path},
        cacheControl: 'public,max-age=3600',
      );

      // 3. Eksekusi Upload
      UploadTask uploadTask = ref.putFile(file, metadata);
      
      // (Opsional) Listen progress
      // uploadTask.snapshotEvents.listen((event) {
      //   double progress = event.bytesTransferred / event.totalBytes;
      //   print('Upload Progress: $progress');
      // });

      await uploadTask;

      // 4. Ambil URL Download
      String downloadUrl = await ref.getDownloadURL();
      
      // Trik Cache Buster (tambah timestamp agar gambar langsung berubah di UI)
      return '$downloadUrl?t=${DateTime.now().millisecondsSinceEpoch}';

    } catch (e) {
      print("❌ Error Upload Firebase: $e");
      Get.snackbar("Gagal Upload", "Terjadi kesalahan saat mengunggah gambar.", 
        backgroundColor: Colors.red, colorText: Colors.white);
      return null;
    }
  }
}