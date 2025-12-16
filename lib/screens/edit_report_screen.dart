import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report_model.dart';
import '../providers/report_provider.dart';

// Hapus import yang tidak diperlukan seperti 'dart:io', 'dart:convert', dan 'package:image_picker/image_picker.dart'

class EditReportScreen extends ConsumerStatefulWidget {
  final ReportModel report;

  const EditReportScreen({super.key, required this.report});

  @override
  ConsumerState<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends ConsumerState<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller untuk data umum laporan
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  // Controller untuk data penyelesaian
  late final TextEditingController _doneDescController;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller Judul dan Deskripsi dengan data yang ada
    _titleController = TextEditingController(text: widget.report.title);
    _descController = TextEditingController(text: widget.report.description);

    // Inisialisasi Deskripsi Pengerjaan dengan data yang sudah ada (jika sudah diisi sebelumnya)
    _doneDescController = TextEditingController(text: widget.report.completionDescription ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _doneDescController.dispose();
    super.dispose();
  }

  // =======================================================
  // FUNGSI SUBMIT (Metadata Only)
  // =======================================================

  // FUNGSI 1: SIMPAN PERUBAHAN METADATA (Judul/Deskripsi)
  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;

    final updates = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
    };

    try {
      await ref.read(reportProvider.notifier).updateReport(widget.report.id, updates);
      if (context.mounted) {
        // Navigasi keluar setelah sukses
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil diperbarui')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error menyimpan perubahan: $e')));
      }
    }
  }

  // FUNGSI 2: MENANDAI SELESAI
  Future<void> _submitComplete() async {
    // Validasi form umum (Judul/Deskripsi)
    if (!_formKey.currentState!.validate()) return;

    // Cek apakah deskripsi pengerjaan diisi (Wajib untuk status Selesai)
    if (_doneDescController.text.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deskripsi Pengerjaan wajib diisi untuk menandai Selesai.')));
        return;
      }
    }

    final updates = <String, dynamic>{
      // Update data laporan utama
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),

      // Update status penyelesaian
      'status': 'selesai',
      'completionDescription': _doneDescController.text.trim(),
      'completedAt': DateTime.now(),

      // Catatan: completionPhotoUrl/Base64 tidak disentuh/dihapus, nilai lamanya dipertahankan.
    };

    try {
      await ref.read(reportProvider.notifier).updateReport(widget.report.id, updates);
      if (context.mounted) {
        // Navigasi keluar setelah sukses
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil diselesaikan!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error menyelesaikan laporan: $e')));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // Tentukan apakah ini mode 'Selesai' (yaitu, statusnya belum selesai)
    final isNotSelesai = widget.report.status.toLowerCase() != 'selesai';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Laporan'),
        backgroundColor: Colors.green,
        actions: [
          // TOMBOL 1: SIMPAN (Update data utama tanpa mengubah status)
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _submitEdit, // Panggil fungsi Simpan
            tooltip: 'Simpan Perubahan',
          ),

          // TOMBOL 2: SELESAI (Hanya muncul jika status BELUM Selesai)
          if (isNotSelesai)
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.white),
              onPressed: _submitComplete, // Panggil fungsi Selesai
              tooltip: 'Tandai Selesai',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- FIELD EDIT JUDUL ---
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Laporan',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),

              // --- FIELD EDIT DESKRIPSI AWAL ---
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Laporan',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Deskripsi tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),

              // --- DETAIL PENYELESAIAN ---
              const Divider(),
              const Text('Deskripsi Pengerjaan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              TextFormField(
                controller: _doneDescController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Pengerjaan Petugas',
                  border: OutlineInputBorder(),
                ),
                // Matikan input jika sudah selesai dan hanya boleh dilihat
                enabled: isNotSelesai,
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 30),

              // Teks peringatan jika sudah selesai
              if (!isNotSelesai)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                      'Laporan ini sudah ditandai sebagai Selesai. Anda dapat memperbarui Judul atau Deskripsi awal laporan, tetapi Deskripsi Pengerjaan tidak dapat diubah.',
                      style: TextStyle(color: Colors.green.shade800)
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}