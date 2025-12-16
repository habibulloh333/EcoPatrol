import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String uid;
  final String title;
  final String description;
  final String imageUrlBase64;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime createdAt;

  final String? completionDescription;
  final String? completionPhotoBase64;
  final DateTime? completedAt;

  ReportModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.description,
    required this.imageUrlBase64,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.completionDescription,
    this.completionPhotoBase64,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'description': description,
      'imageUrlBase64': imageUrlBase64,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'createdAt': createdAt,
      'completionDescription': completionDescription,
      'completionPhotoBase64': completionPhotoBase64,
      'completedAt': completedAt,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReportModel(
      id: docId,
      uid: map['uid'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrlBase64: map['imageUrlBase64'] ?? '', // <-- DIGANTI
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),

      completionDescription: map['completionDescription'] as String?,
      completionPhotoBase64: map['completionPhotoBase64'] as String?,
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  // 3. Metode untuk memudahkan Update State
  ReportModel copyWith({
    String? id,
    String? uid,
    String? title,
    String? description,
    String? imageUrlBase64,
    double? latitude,
    double? longitude,
    String? status,
    DateTime? createdAt,
    String? completionDescription,
    String? completionPhotoBase64,
    DateTime? completedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrlBase64: imageUrlBase64 ?? this.imageUrlBase64,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,

      // Field baru Mhs 4
      completionDescription: completionDescription ?? this.completionDescription,
      completionPhotoBase64: completionPhotoBase64 ?? this.completionPhotoBase64,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}