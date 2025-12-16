import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  final TextEditingController _doneDescController = TextEditingController();
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _doneDescController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource src) async {
    final XFile? xfile = await _picker.pickImage(source: src, imageQuality: 80);
    if (xfile != null) {
      setState(() {
        _pickedImage = File(xfile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final updates = <String, dynamic>{
      'status': 'selesai',
      'doneDescription': _doneDescController.text.trim(),
    };

    if (_pickedImage != null) {
      try {
        final url = await _uploadDoneImage(_pickedImage!);
        updates['doneImage'] = url;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload gambar: $e')));
          return;
        }
      }
    }

    try {
      await ref.read(reportProvider.notifier).updateReport(widget.report.id, updates);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil diperbarui')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<String> _uploadDoneImage(File file) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = FirebaseStorage.instance.ref().child('done_images').child('${widget.report.id}_$ts.jpg');
    final uploadTask = await ref.putFile(file);
    final url = await ref.getDownloadURL();
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selesaikan Laporan'), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Laporan: ${widget.report.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _doneDescController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Pengerjaan',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Isi deskripsi pengerjaan' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo),
                    label: const Text('Galeri'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (_pickedImage != null)
                SizedBox(
                  height: 150,
                  child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_pickedImage!, fit: BoxFit.cover)),
                ),

              const Spacer(),

              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _submit,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Simpan dan Tandai Selesai'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
