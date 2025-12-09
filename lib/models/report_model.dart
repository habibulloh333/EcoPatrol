import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;          // ID unik dokumen di Firestore
  final String uid;         // ID User yang melapor
  final String title;       // Judul laporan (misal: "Sampah Liar di Jalan A")
  final String description; // Detail laporan
  final String imageUrl;    // URL foto (dari Storage - tugas mhs lain, kita siapin wadahnya)
  final double latitude;    // Koordinat GPS
  final double longitude;   // Koordinat GPS
  final String status;      // "pending", "proses", "selesai"
  final DateTime createdAt; // Tanggal lapor

  ReportModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
  });

  // 1. Mengubah Object menjadi Map (JSON) untuk dikirim ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'createdAt': createdAt, // Firestore otomatis convert DateTime
    };
  }

  // 2. Mengubah Map dari Firestore menjadi Object Dart
  factory ReportModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReportModel(
      id: docId,
      uid: map['uid'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      // Konversi aman untuk angka (kadang terbaca int, harus double)
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      // Konversi Timestamp Firestore ke DateTime Dart
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}