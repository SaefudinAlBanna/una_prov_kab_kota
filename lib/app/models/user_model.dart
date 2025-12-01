import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String email;
  String nama;
  String role;        // 'dinas_prov', 'dinas_kab', 'pegawai', 'wali_murid'
  String? fotoUrl;
  
  // -- Field Identitas Wilayah --
  String? scopeProv;  // Kode Provinsi (untuk Dinas Prov)
  String? scopeDist;  // Kode Kab/Kota (untuk Dinas Kab)
  String? idSekolah;  // ID Sekolah (untuk Pegawai/Ortu)
  String? nip;       // Tambahan untuk profil lengkap
  String? noHp;      // Tambahan untuk profil lengkap

  // FIELD KEAMANAN BARU
  bool mustChangePassword;
  bool isProfileComplete;

  UserModel({
    required this.uid,
    required this.email,
    required this.nama,
    required this.role,
    this.fotoUrl,
    this.scopeProv,
    this.scopeDist,
    this.idSekolah,

    this.nip,
    this.noHp,
    this.mustChangePassword = false,
    this.isProfileComplete = true, // Default true untuk user lama/dinas
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      nama: data['nama'] ?? 'Tanpa Nama',
      role: data['role'] ?? 'guest',
      fotoUrl: data['profileImageUrl'] ?? data['fotoUrl'], // Handle legacy field
      scopeProv: data['scopeProv'],
      scopeDist: data['scopeDist'],
      idSekolah: data['idSekolah'],

      nip: data['nip'],
      noHp: data['noHp'],
      // Parsing logic boolean
      mustChangePassword: data['mustChangePassword'] ?? false,
      isProfileComplete: data['isProfileComplete'] ?? true, // Default true jika field tidak ada
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'nama': nama,
    'role': role,
    'profileImageUrl': fotoUrl,
    'scopeProv': scopeProv,
    'scopeDist': scopeDist,
    'idSekolah': idSekolah,

    'nip': nip,
      'noHp': noHp,
      'mustChangePassword': mustChangePassword,
      'isProfileComplete': isProfileComplete,
    };
}