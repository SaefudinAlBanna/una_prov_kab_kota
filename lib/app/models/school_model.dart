class SchoolModel {
  String? id;
  String npsn;
  String nama;
  String alamat;
  String provinceId;
  String districtId;
  String? jenjang;   // SD, SMP, SMA
  
  // FIELD BARU
  String? kecamatan; // e.g. "Kecamatan Depok"
  String? status;    // e.g. "Negeri" atau "Swasta"
  
  DateTime? createdAt;

  SchoolModel({
    this.id,
    required this.npsn,
    required this.nama,
    required this.alamat,
    required this.provinceId,
    required this.districtId,
    this.jenjang,
    this.kecamatan, // Baru
    this.status,    // Baru
    this.createdAt,
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json, String docId) {
    return SchoolModel(
      id: docId,
      npsn: json['npsn'] ?? '',
      nama: json['nama'] ?? '',
      alamat: json['alamat'] ?? '',
      provinceId: json['provinceId'] ?? '',
      districtId: json['districtId'] ?? '',
      jenjang: json['jenjang'],
      kecamatan: json['kecamatan'], // Baru
      status: json['status'],       // Baru
      createdAt: json['createdAt'] != null ? (json['createdAt'] as dynamic).toDate() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'npsn': npsn,
      'nama': nama,
      'alamat': alamat,
      'provinceId': provinceId,
      'districtId': districtId,
      'jenjang': jenjang,
      'kecamatan': kecamatan, // Baru
      'status': status,       // Baru
      'createdAt': createdAt ?? DateTime.now(),
    };
  }
}