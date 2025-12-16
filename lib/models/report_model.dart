// lib/models/report_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id; // ID unik dokumen di Firestore
  final String uid; // ID User yang melapor
  final String title; // Judul laporan
  final String description; // Detail laporan
  final String imageUrl; // URL foto bukti awal
  final double latitude; // Koordinat GPS
  final double longitude; // Koordinat GPS
  final String status; // "pending", "proses", "selesai"
  final DateTime createdAt; // Tanggal lapor

  // --- FIELD BARU UNTUK MAHASISWA 4 (PENYELESAIAN) ---
  final String? completionDescription; // Deskripsi pekerjaan oleh petugas
  final String? completionPhotoUrl; // URL foto hasil pengerjaan (dari Storage)
  final DateTime? completedAt; // Waktu penyelesaian

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
    // Field baru opsional
    this.completionDescription,
    this.completionPhotoUrl,
    this.completedAt,
  });

  // 1. Mengubah Object menjadi Map (JSON) untuk dikirim ke Firestore
  // Digunakan untuk INSERT (CREATE) dan UPDATE
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'createdAt': createdAt,

      // Field baru Mhs 4
      'completionDescription': completionDescription,
      'completionPhotoUrl': completionPhotoUrl,
      'completedAt': completedAt,
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
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),

      // Field baru Mhs 4 (bisa null)
      completionDescription: map['completionDescription'] as String?,
      completionPhotoUrl: map['completionPhotoUrl'] as String?,
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  // 3. Metode untuk memudahkan Update State (dan mempersiapkan data update)
  ReportModel copyWith({
    String? id,
    String? uid,
    String? title,
    String? description,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? status,
    DateTime? createdAt,
    // Field baru Mhs 4
    String? completionDescription,
    String? completionPhotoUrl,
    DateTime? completedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,

      // Field baru Mhs 4
      completionDescription: completionDescription ?? this.completionDescription,
      completionPhotoUrl: completionPhotoUrl ?? this.completionPhotoUrl,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}