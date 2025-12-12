import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/report_model.dart';
import '../providers/report_provider.dart';
import '../providers/auth_provider.dart';

class AddReportScreen extends ConsumerStatefulWidget {
  const AddReportScreen({super.key});

  @override
  ConsumerState<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends ConsumerState<AddReportScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  File? _imageFile;
  double? _lat;
  double? _lon;

  bool _isLoading = false;


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


  Future<void> _pickImageWithPermission(ImageSource source) async {
    bool allowed = false;

    if (source == ImageSource.camera) {
      allowed = await _checkCameraPermission();
      if (!allowed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Izin kamera ditolak")),
        );
        return;
      }
    } else {
      allowed = await _checkGalleryPermission();
      if (!allowed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Izin galeri ditolak")),
        );
        return;
      }
    }

    _pickImage(source);
  }


  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 70);

    if (file != null) {
      setState(() {
        _imageFile = File(file.path);
      });
    }
  }

  Future<void> _getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    bool allowed = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Izin lokasi ditolak")),
      );
      return;
    }

    Position pos = await Geolocator.getCurrentPosition();
    setState(() {
      _lat = pos.latitude;
      _lon = pos.longitude;
    });
  }

  Future<void> _submitReport() async {
    if (_titleController.text.isEmpty ||
        _descController.text.isEmpty ||
        _imageFile == null ||
        _lat == null ||
        _lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua data harus lengkap!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider);
      if (user == null) throw Exception("User belum login");

      final report = ReportModel(
        id: '',
        uid: user.uid,
        title: _titleController.text,
        description: _descController.text,
        imageUrl: _imageFile!.path,
        latitude: _lat!,
        longitude: _lon!,
        status: "pending",
        createdAt: DateTime.now(),
      );

      await ref.read(reportProvider.notifier).addReport(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Laporan berhasil dikirim!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengirim laporan: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Laporan"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.green[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // INPUT JUDUL
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Judul Laporan",
                prefixIcon: const Icon(Icons.edit),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // INPUT DESKRIPSI
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: "Deskripsi",
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // PREVIEW FOTO
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _imageFile == null
                  ? const Center(child: Text("Belum ada foto"))
                  : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_imageFile!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),

            // BUTTON FOTO KAMERA & GALERI
            Row(
              children: [
                // KAMERA
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Kamera"),
                    onPressed: () => _pickImageWithPermission(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 10),

                // GALERI
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Galeri"),
                    onPressed: () =>
                        _pickImageWithPermission(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // KOTAK KOORDINAT RINGKAS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Koordinat Saat Ini:",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _lat == null ? "Latitude: -" : "Latitude: $_lat",
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    _lon == null ? "Longitude: -" : "Longitude: $_lon",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // BUTTON GET LOCATION
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              icon: const Icon(Icons.location_on),
              label: const Text("Tag Lokasi Terkini"),
              onPressed: _getLocation,
            ),

            const SizedBox(height: 30),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitReport,
                child: const Text(
                  "KIRIM LAPORAN",
                  style:
                  TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
