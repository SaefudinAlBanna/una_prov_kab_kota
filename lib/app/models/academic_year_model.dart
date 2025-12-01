import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicYearModel {
  String? id;
  String nama; // Di UI tetap "nama", tapi di DB "namatahunajaran"
  String semesterAktif; 
  bool isAktif; // [UBAH] isAktive -> isAktif
  DateTime? createdAt;

  AcademicYearModel({
    this.id,
    required this.nama,
    required this.semesterAktif,
    this.isAktif = false, // Default
    this.createdAt,
  });

  factory AcademicYearModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AcademicYearModel(
      id: doc.id,
      // [PENTING] Mapping dari field Legacy
      nama: data['namatahunajaran'] ?? data['nama'] ?? '', 
      semesterAktif: data['semesterAktif'] ?? '1',
      // [PENTING] Mapping boolean legacy
      isAktif: data['isAktif'] ?? data['isAktive'] ?? false, 
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'namatahunajaran': nama, // [UBAH] Simpan sebagai namatahunajaran
      'semesterAktif': semesterAktif,
      'isAktif': isAktif, // [UBAH] Simpan sebagai isAktif
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}