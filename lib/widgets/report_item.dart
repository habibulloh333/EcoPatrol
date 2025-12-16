import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../models/report_model.dart';

class ReportItem extends StatelessWidget {
  final ReportModel report;
  final VoidCallback? onTap;

  const ReportItem({super.key, required this.report, this.onTap});

  // TAMPILKAN FOTO FULL SIZE
  void _showFullImage(BuildContext context, Uint8List bytes) {
    if (bytes.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Foto Bukti Awal', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET HELPER: MEMBANGUN GAMBAR DARI BASE64
  Widget _buildImage(BuildContext context, String base64String) {
    if (base64String.isEmpty) {
      return const Icon(Icons.image, color: Colors.grey, size: 30);
    }

    Uint8List? imageBytes;
    try {
      imageBytes = base64Decode(base64String);
    } catch (e) {
      return const Icon(Icons.broken_image, color: Colors.red, size: 30);
    }

    return GestureDetector(
      onTap: () => _showFullImage(context, imageBytes!), // Klik untuk Full Screen
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          errorBuilder: (ctx, error, stackTrace) =>
          const Icon(Icons.broken_image, color: Colors.red, size: 30),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSelesai = report.status.toLowerCase() == 'selesai';
    final statusColor = isSelesai ? Colors.green : Colors.orange;
    final statusText = isSelesai ? "Selesai" : "Pending";

    final imageBase64 = report.imageUrlBase64;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 70,
                height: 70,
                color: Colors.grey[200],
                child: _buildImage(context, imageBase64),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Lat: ${report.latitude.toStringAsFixed(4)}...",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}