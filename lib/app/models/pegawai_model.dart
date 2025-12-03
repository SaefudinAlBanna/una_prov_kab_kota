import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/user_role_enum.dart'; 

class PegawaiModel {
  final String uid;
  final String nama;
  final String? alias;
  final UserRole role;
  final String? profileImageUrl;
  final String? email; 
  final String? jenisKelamin; 
  
  final List<String> tugas;
  final String? roleString; 

  PegawaiModel({
    required this.uid,
    required this.nama,
    this.alias,
    required this.role,
    this.profileImageUrl,
    this.email,
    this.jenisKelamin,
    required this.tugas, 
    this.roleString,    
  });

  factory PegawaiModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final roleMentah = data['role'] as String?;

    return PegawaiModel(
      uid: doc.id,
      nama: data['nama'] ?? 'Tanpa Nama',
      alias: data['alias'] as String?,
      email: data['email'] as String?,
      jenisKelamin: data['jeniskelamin'] as String?,
      role: UserRole.fromString(roleMentah), 
      profileImageUrl: data['profileImageUrl'] as String?,
      tugas: List<String>.from(data['tugas'] ?? []),
      roleString: roleMentah, 
    );
  }
}