import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // <-- BARU: Tambahkan untuk Base64 Decode
import 'dart:typed_data'; // <-- BARU: Tambahkan untuk Uint8List

import '../models/report_model.dart';
import '../providers/report_provider.dart';
import 'edit_report_screen.dart';

class DetailReportScreen extends ConsumerWidget {
  final ReportModel report;

  const DetailReportScreen({super.key, required this.report});

  // WIDGET HELPER UNTUK MENAMPILKAN GAMBAR Menggunakan Base64
  Widget _buildImage(BuildContext context, String base64String) {
    if (base64String.isEmpty) {
      // Kotak jika foto tidak ada
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 60),
      );
    }

    // Konversi Base64 string ke bytes
    final Uint8List bytes = base64Decode(base64String);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GestureDetector(
        onTap: () => _showFullImage(context, bytes),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  // LOGIKA HELPER: TAMPILKAN FOTO FULL SIZE (Menggunakan Base64)
  void _showFullImage(BuildContext context, Uint8List bytes) {
    if (bytes.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.memory( // Menggunakan Image.memory
              bytes,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  // LOGIKA HAPUS (MEMANGGIL PROVIDER) - Tidak diubah
  void _confirmDelete(BuildContext context, WidgetRef ref, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Yakin ingin menghapus laporan ini secara permanen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (ok == true) {
      try {
        await ref.read(reportProvider.notifier).deleteReport(id);

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan dihapus')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error menghapus: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelesai = report.status.toLowerCase() == 'selesai';

    // ASUMSI: report.imageUrlBase64 adalah String Base64 atau string kosong
    final imageBase64 = report.imageUrlBase64.isEmpty ? '' : report.imageUrlBase64;
    // ASUMSI: report.completionPhotoBase64 adalah String Base64 atau string kosong
    final completionImageBase64 = report.completionPhotoBase64 ?? '';


    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        backgroundColor: Colors.green,
        actions: [
          if (!isSelesai)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditReportScreen(report: report),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. FOTO BUKTI AWAL ---
              _buildImage(context, imageBase64), // <-- Menggunakan Base64
              const SizedBox(height: 10),

              // --- DETAIL DATA AWAL ---
              Text(report.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Status: ${report.status.toUpperCase()}', style: TextStyle(
                color: isSelesai ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 8),
              Text(report.description),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('Dilaporkan pada: ${DateFormat('dd MMM yyyy, HH:mm').format(report.createdAt)}'),
                ],
              ),
              const SizedBox(height: 24),

              // --- DETAIL PENYELESAIAN (Jika Selesai) ---
              if (isSelesai) ...[
                const Divider(thickness: 1),
                const Text(
                  'Hasil Pekerjaan Petugas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 8),
                Text('Deskripsi Pekerjaan:', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(report.completionDescription ?? 'Tidak ada deskripsi.'),
                const SizedBox(height: 12),

                // --- FOTO PENYELESAIAN ---
                if (completionImageBase64.isNotEmpty) ...[
                  const Text('Foto Hasil Pekerjaan:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildImage(context, completionImageBase64), // <-- Menggunakan Base64
                ],

                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('Selesai pada: ${report.completedAt != null
                        ? DateFormat('dd MMM yyyy, HH:mm').format(report.completedAt!)
                        : 'Waktu belum tersimpan'}'),
                  ],
                ),
                const SizedBox(height: 18),
              ],

              // --- Action buttons ---
              Row(
                children: [
                  if (!isSelesai)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        icon: const Icon(Icons.check),
                        label: const Text('Tandai Selesai'),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditReportScreen(report: report),
                            ),
                          );
                        },
                      ),
                    ),

                  if (!isSelesai) const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      icon: const Icon(Icons.delete),
                      label: const Text('Hapus Laporan'),
                      onPressed: () => _confirmDelete(context, ref, report.id),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}