class UserModel {
  final String uid;
  final String nama;
  final String email;
  final String nim;
  final String prodi;
  final String kelas;
  final String role;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.nim,
    required this.prodi,
    required this.kelas,
    required this.role,
    this.fcmToken,
  });

  // Mengubah data user menjadi Map (untuk dikirim ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'email': email,
      'nim': nim,
      'prodi': prodi,
      'kelas': kelas,
      'role': role,
      'fcm_token': fcmToken,
    };
  }

  // Mengubah data Map dari Firestore menjadi objek User (untuk dipakai di aplikasi)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      nim: map['nim'] ?? '',
      prodi: map['prodi'] ?? '',
      kelas: map['kelas'] ?? '',
      role: map['role'] ?? 'mahasiswa',
      fcmToken: map['fcm_token'],
    );
  }
}