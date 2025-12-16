import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report_model.dart';
import '../providers/report_provider.dart';
import 'edit_report_screen.dart';

class DetailReportScreen extends ConsumerWidget {
  final ReportModel report;

  const DetailReportScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelesai = report.status.toLowerCase() == 'selesai';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showFullImage(context, report.imageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: _buildImage(report.imageUrl),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                report.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(report.description),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('Lat: ${report.latitude.toStringAsFixed(6)}  |  Lng: ${report.longitude.toStringAsFixed(6)}'),
                ],
              ),
              const SizedBox(height: 18),

              // Action buttons
              Row(
                children: [
                  if (!isSelesai)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        icon: const Icon(Icons.check),
                        label: const Text('Tandai Selesai'),
                        onPressed: () async {
                          // Navigate to edit screen to add description + photo hasil kerja
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.isEmpty) return const Icon(Icons.image, color: Colors.grey, size: 60);
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    } else {
      return const Icon(Icons.broken_image, color: Colors.grey, size: 60);
    }
  }

  void _showFullImage(BuildContext context, String path) {
    if (path.isEmpty) return;
    final file = File(path);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: file.existsSync()
              ? Image.file(file, fit: BoxFit.contain)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin menghapus laporan ini?'),
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
          Navigator.pop(context); // close detail
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan dihapus')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
