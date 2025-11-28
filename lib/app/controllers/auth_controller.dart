import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../routes/app_pages.dart';

class AuthController extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  late final Stream<User?> authStateChanges;
  final Rxn<User> _firebaseUser = Rxn<User>();
  final Rxn<UserModel> currentUserModel = Rxn<UserModel>(); 
  
  Rxn<UserModel> get userModel => currentUserModel; 
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    authStateChanges = auth.authStateChanges();
    _firebaseUser.bindStream(authStateChanges);
    
    // Stream hanya untuk Auto-Login saat aplikasi baru dibuka/restart
    ever(_firebaseUser, (User? user) {
      print("👻 STREAM AUTH TRIGGERED: User is ${user == null ? 'Null' : 'Found'}");
      if (user != null) {
        // Jangan navigasi otomatis jika kita sedang loading manual (login form)
        // Biarkan fungsi login() yang menangani navigasinya agar Thread Safe
        if (!isLoading.value) {
          _fetchUserProfile(user.uid);
        }
      } else {
        Get.offAllNamed(Routes.LOGIN);
      }
    });
  }

  Future<void> loadUser() async {
    if (auth.currentUser != null) {
      await _fetchUserProfile(auth.currentUser!.uid);
    }
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      print("🔍 FETCHING PROFIL: $uid");
      DocumentSnapshot doc = await firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        print("✅ PROFIL DITEMUKAN: ${doc.data()}");
        UserModel userM = UserModel.fromFirestore(doc); 
        currentUserModel.value = userM;
        
        // Cek apakah Navigasi diperlukan (hanya jika belum di dashboard)
        if (Get.currentRoute != Routes.DASHBOARD) {
          _navigateBasedOnRole(userM);
        }
      } else {
        print("❌ PROFIL TIDAK DITEMUKAN DI FIRESTORE");
        Get.snackbar("Error", "Data user tidak ditemukan di database.");
        await logout();
      }
    } catch (e) {
      print("❌ ERROR FETCH USER: $e");
      Get.snackbar("Error", "Gagal mengambil profil: $e");
    }
  }

  void _navigateBasedOnRole(UserModel user) {
    print("🚦 NAVIGASI KE DASHBOARD. Role: ${user.role}");
    
    // [FIX WINDOWS THREADING] Pastikan UI update di Main Thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
       switch (user.role) {
        case 'dinas_prov':
        case 'dinas_kab':
        case 'pegawai':
        case 'wali_murid':
          Get.offAllNamed(Routes.DASHBOARD); 
          break;
        default:
          Get.snackbar("Akses Ditolak", "Role ${user.role} tidak dikenali.");
          logout();
      }
    });
  }

  // LOGIC LOGIN YANG DIPERBAIKI
  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      print("🔑 MEMULAI LOGIN: $email");

      // 1. Auth Firebase
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email.trim(), 
        password: password.trim()
      );

      // 2. Jika sukses, Ambil Data Profil SECARA MANUAL (Thread Safe)
      // Kita tidak menunggu Stream, tapi langsung eksekusi urut.
      if (userCredential.user != null) {
        print("🔓 AUTH SUKSES. Mengambil profil...");
        await _fetchUserProfile(userCredential.user!.uid);
      }

    } on FirebaseAuthException catch (e) {
      print("❌ LOGIN GAGAL (Auth): ${e.message}");
      Get.snackbar("Login Gagal", e.message ?? "Terjadi kesalahan", 
        backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
       print("❌ LOGIN GAGAL (General): $e");
       Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await auth.signOut();
    currentUserModel.value = null;
    Get.offAllNamed(Routes.LOGIN);
  }
}


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../models/user_model.dart';
// import '../routes/app_pages.dart';

// class AuthController extends GetxController {
//   final FirebaseAuth auth = FirebaseAuth.instance;
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
//   late final Stream<User?> authStateChanges;
//   final Rxn<User> _firebaseUser = Rxn<User>();
//   final Rxn<UserModel> currentUserModel = Rxn<UserModel>(); // Data User Lengkap
//   final RxBool isLoading = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     authStateChanges = auth.authStateChanges();
//     _firebaseUser.bindStream(authStateChanges);
    
//     // Listener: Setiap kali status login berubah, cek role
//     ever(_firebaseUser, _handleAuthChanged);
//   }

//   Future<void> _handleAuthChanged(User? user) async {
//     if (user == null) {
//       Get.offAllNamed(Routes.LOGIN); // Ganti Routes.ROOT jadi LOGIN biar jelas
//     } else {
//       await _fetchUserProfile(user.uid);
//     }
//   }

//   Future<void> _fetchUserProfile(String uid) async {
//     try {
//       DocumentSnapshot doc = await firestore.collection('users').doc(uid).get();
      
//       if (doc.exists) {
//         UserModel userModel = UserModel.fromFirestore(doc);
//         currentUserModel.value = userModel;
        
//         // --- ROUTING LOGIC (TRAFFIC POLICE) ---
//         _navigateBasedOnRole(userModel);
        
//       } else {
//         Get.snackbar("Error", "Data user tidak ditemukan di database.");
//         await logout();
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Gagal mengambil profil: $e");
//     }
//   }

//   void _navigateBasedOnRole(UserModel user) {
//     print("🚦 Navigasi Role: ${user.role}");
    
//     switch (user.role) {
//       case 'dinas_prov':
//         // Get.offAllNamed(Routes.DINAS_PROV_DASHBOARD); 
//         // Sementara kita arahkan ke Home biasa dulu sampai modul jadi
//         Get.offAllNamed(Routes.HOME); 
//         break;
        
//       case 'dinas_kab':
//         // Ini target utama kita sekarang
//         Get.offAllNamed(Routes.HOME); // Nanti ganti Routes.DINAS_KAB_DASHBOARD
//         break;
        
//       case 'pegawai':
//         // Sekolah
//         Get.offAllNamed(Routes.HOME); // Nanti ganti Routes.SCHOOL_DASHBOARD
//         break;
        
//       case 'wali_murid':
//         Get.offAllNamed(Routes.HOME); // Nanti ganti Routes.PARENT_DASHBOARD
//         break;
        
//       default:
//         Get.snackbar("Akses Ditolak", "Role tidak dikenali.");
//         logout();
//     }
//   }

//   Future<void> login(String email, String password) async {
//     try {
//       isLoading.value = true;
//       await auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
//       // Listener _handleAuthChanged akan otomatis jalan setelah ini
//     } on FirebaseAuthException catch (e) {
//       Get.snackbar("Login Gagal", e.message ?? "Terjadi kesalahan", 
//         backgroundColor: Colors.red, colorText: Colors.white);
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> logout() async {
//     await auth.signOut();
//     currentUserModel.value = null;
//     Get.offAllNamed(Routes.LOGIN);
//   }
// }