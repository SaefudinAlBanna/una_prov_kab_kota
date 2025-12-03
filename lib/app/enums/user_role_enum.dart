enum UserRole {
  admin('Admin'),
  kepalaSekolah('Kepala Sekolah'),
  operator('Operator'),
  tu('TU'),
  tataUsaha('Tata Usaha'),
  guruKelas('Guru Kelas'),
  guruMapel('Guru Mapel'),
  superAdmin('Super Admin'),
  
  tidakDiketahui('Tidak Diketahui');

  const UserRole(this.displayName);
  final String displayName;

  static UserRole fromString(String? roleString) {
    switch (roleString) {
      case 'Admin': return UserRole.admin;
      case 'Kepala Sekolah': return UserRole.kepalaSekolah;
      case 'Operator': return UserRole.operator;
      case 'TU': return UserRole.tu;
      case 'Tata Usaha': return UserRole.tataUsaha;
      case 'Guru Kelas': return UserRole.guruKelas;
      case 'Guru Mapel': return UserRole.guruMapel;
      case 'superadmin': return UserRole.superAdmin;
      default: return UserRole.tidakDiketahui;
    }
  }
}