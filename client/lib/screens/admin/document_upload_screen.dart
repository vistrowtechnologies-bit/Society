import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class DocumentUploadScreen extends StatefulWidget {
  final int societyId;

  const DocumentUploadScreen({super.key, required this.societyId});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _titleController = TextEditingController();
  String _category = 'Bye-laws';
  PlatformFile? _file;
  bool _loading = false;
  String? _error;

  final _categories = const ['Bye-laws', 'AGM minutes', 'Certificates', 'Circulars', 'General'];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _file = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (_file == null || _titleController.text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiClient.uploadDocument(
        societyId: widget.societyId,
        category: _category,
        title: _titleController.text.trim(),
        fileBytes: _file!.bytes!.toList(),
        filename: _file!.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded')));
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit society document')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Annual General Meeting Report 2024'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(_file?.name ?? 'Choose file'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
