import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import '../models/report_model.dart';
import '../providers/report_provider.dart';

class EditReportScreen extends ConsumerStatefulWidget {
  final ReportModel report;

  const EditReportScreen({super.key, required this.report});

  @override
  ConsumerState<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends ConsumerState<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _doneDescController;

  //STATE BARU UNTUK GAMBAR
  File? _newInitialImageFile; // File foto awal yang baru dipilih
  File? _newCompletionImageFile; // File foto penyelesaian yang baru dipilih

  String? _initialImageBase64; // Base64 foto awal (lama atau baru)
  String? _completionImageBase64; // Base64 foto pestilential (lama atau baru)

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.report.title);
    _descController = TextEditingController(text: widget.report.description);
    _doneDescController = TextEditingController(text: widget.report.completionDescription ?? '');

    // Inisialisasi Base64 string dengan data lama
    _initialImageBase64 = widget.report.imageUrlBase64;
    _completionImageBase64 = widget.report.completionPhotoBase64;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _doneDescController.dispose();
    super.dispose();
  }

  // --- FUNGSI PERMISSION & PICK IMAGE (SAMA DENGAN ADD REPORT SCREEN) ---

  Future<bool> _checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  Future<bool> _checkGalleryPermission() async {
    var status = await Permission.photos.status;
    if (status.isDenied) {
      status = await Permission.photos.request();
    }
    return status.isGranted;
  }

  Future<void> _pickImageWithPermission(ImageSource source, bool isInitialImage) async {
    bool allowed = false;

    if (source == ImageSource.camera) {
      allowed = await _checkCameraPermission();
    } else {
      allowed = await _checkGalleryPermission();
    }

    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Izin ${source == ImageSource.camera ? 'kamera' : 'galeri'} ditolak")),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 70);

    if (file != null) {
      final bytes = await File(file.path).readAsBytes();
      final base64String = base64Encode(bytes);

      setState(() {
        if (isInitialImage) {
          _newInitialImageFile = File(file.path);
          _initialImageBase64 = base64String;
        } else {
          _newCompletionImageFile = File(file.path);
          _completionImageBase64 = base64String;
        }
      });
    }
  }

  // --- WIDGET HELPER: MENAMPILKAN GAMBAR BASE64 ---
  Widget _buildImagePreview(String? base64, File? file, {required double height, required bool canChange}) {
    // 1. Coba tampilkan File baru (jika ada)
    if (file != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(file, fit: BoxFit.cover, height: height, width: double.infinity),
      );
    }
    // 2. Coba tampilkan Base64 lama
    else if (base64 != null && base64.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(base64);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, fit: BoxFit.cover, height: height, width: double.infinity),
        );
      } catch (e) {
        // Gagal decode
        return Center(child: Text(canChange ? "Gambar rusak/tidak valid" : "Gambar rusak/tidak valid (Base64)", textAlign: TextAlign.center));
      }
    }
    // 3. Placeholder
    return Center(child: Text(canChange ? "Klik tombol di bawah untuk menambah foto" : "Belum ada foto penyelesaian"));
  }

  // =======================================================
  // FUNGSI SUBMIT (Metadata Only)
  // =======================================================

  // FUNGSI 1: SIMPAN PERUBAHAN METADATA (Judul/Deskripsi/Foto Awal)
  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final updates = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      // Tambahkan Base64 baru atau lama
      'imageUrlBase64': _initialImageBase64 ?? '',
    };

    try {
      await ref.read(reportProvider.notifier).updateReport(widget.report.id, updates);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil diperbarui')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error menyimpan perubahan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // FUNGSI 2: MENANDAI SELESAI (Update status dan Foto Penyelesaian)
  Future<void> _submitComplete() async {
    if (!_formKey.currentState!.validate()) return;

    if (_doneDescController.text.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deskripsi Pengerjaan wajib diisi untuk menandai Selesai.')));
      }
      return;
    }

    // Validasi tambahan: Foto penyelesaian wajib diisi saat menandai selesai
    if (_completionImageBase64 == null || _completionImageBase64!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto Hasil Pekerjaan wajib diisi untuk menandai Selesai.')));
      }
      return;
    }

    setState(() => _isLoading = true);

    final updates = <String, dynamic>{
      // Update data laporan utama
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'imageUrlBase64': _initialImageBase64 ?? '',

      // Update status penyelesaian
      'status': 'selesai',
      'completionDescription': _doneDescController.text.trim(),
      'completedAt': DateTime.now(),
      'completionPhotoBase64': _completionImageBase64 ?? '', // Base64 foto penyelesaian baru/lama
    };

    try {
      await ref.read(reportProvider.notifier).updateReport(widget.report.id, updates);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil diselesaikan!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error menyelesaikan laporan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final isNotSelesai = widget.report.status.toLowerCase() != 'selesai';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Laporan'),
        backgroundColor: Colors.green,
        actions: [
          _isLoading
              ? const Center(child: Padding(
            padding: EdgeInsets.only(right: 16),
            child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)),
          ))
              : IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _submitEdit,
            tooltip: 'Simpan Perubahan',
          ),

          if (isNotSelesai)
            _isLoading
                ? const SizedBox.shrink()
                : IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.white),
              onPressed: _submitComplete,
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

              // --- FOTO BUKTI AWAL ---
              const Text('Foto Bukti Awal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _buildImagePreview(_initialImageBase64, _newInitialImageFile, height: 200, canChange: true),
              ),
              const SizedBox(height: 12),

              // BUTTON GANTI FOTO AWAL
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Kamera"),
                      onPressed: () => _pickImageWithPermission(ImageSource.camera, true), // true = Initial Image
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Galeri"),
                      onPressed: () => _pickImageWithPermission(ImageSource.gallery, true), // true = Initial Image
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),


              // --- DETAIL PENYELESAIAN ---
              const Divider(),
              const Text('Pengerjaan oleh Petugas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // 1. Deskripsi Pengerjaan
              TextFormField(
                controller: _doneDescController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Pengerjaan Petugas',
                  border: OutlineInputBorder(),
                ),
                enabled: isNotSelesai,
              ),
              const SizedBox(height: 12),

              // 2. Foto Penyelesaian (Hanya bisa diubah jika status belum selesai)
              const Text('Foto Hasil Pekerjaan (Wajib diisi jika status Selesai)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _buildImagePreview(_completionImageBase64, _newCompletionImageFile, height: 200, canChange: isNotSelesai),
              ),
              const SizedBox(height: 12),

              // BUTTON GANTI FOTO PENYELESAIAN (Hanya muncul jika belum selesai)
              if (isNotSelesai)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Kamera"),
                        onPressed: () => _pickImageWithPermission(ImageSource.camera, false), // false = Completion Image
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Galeri"),
                        onPressed: () => _pickImageWithPermission(ImageSource.gallery, false), // false = Completion Image
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 30),

              if (!isNotSelesai)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                      'Laporan ini sudah ditandai sebagai Selesai. Anda hanya dapat memperbarui Judul, Deskripsi awal laporan, atau Foto Bukti Awal.',
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