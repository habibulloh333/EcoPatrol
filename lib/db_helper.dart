import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/report_model.dart';

class DbHelper {
  // Inisialisasi koleksi 'reports' di Firestore
  final CollectionReference _reportCollection =
  FirebaseFirestore.instance.collection('reports');

  // Fungsi Create: Menambah laporan baru
  Future<void> addReport(ReportModel report) async {
    try {
      await _reportCollection.add(report.toMap());
    } catch (e) {
      throw Exception('Gagal kirim laporan: $e');
    }
  }

  // Fungsi Read: Mengambil semua laporan (Stream agar realtime)
  Stream<List<ReportModel>> getReports() {
    return _reportCollection
        .orderBy('createdAt', descending: true) // Urutkan dari yang terbaru
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // Ubah tiap dokumen jadi objek ReportModel
        return ReportModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id
        );
      }).toList();
    });
  }

  // Fungsi Update: Mengubah beberapa field pada laporan
  Future<void> updateReport(String id, Map<String, dynamic> fields) async {
    try {
      await _reportCollection.doc(id).update(fields);
    } catch (e) {
      throw Exception('Gagal update laporan: $e');
    }
  }

  // Fungsi Delete: Menghapus laporan berdasarkan id
  Future<void> deleteReport(String id) async {
    try {
      await _reportCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Gagal hapus laporan: $e');
    }
  }
}