import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';

class RaiseComplaintScreen extends StatefulWidget {
  final int flatId;

  const RaiseComplaintScreen({super.key, required this.flatId});

  @override
  State<RaiseComplaintScreen> createState() => _RaiseComplaintScreenState();
}

class _RaiseComplaintScreenState extends State<RaiseComplaintScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _category;
  bool _loading = false;
  String? _error;

  final _categories = const [
    ('plumbing', 'Plumbing'),
    ('electrical', 'Electrical'),
    ('carpentry', 'Carpentry'),
    ('cleaning', 'Cleaning'),
    ('security', 'Security'),
    ('other', 'Other'),
  ];

  Future<void> _submit() async {
    if (_category == null || _titleController.text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiClient.raiseComplaint(
        flatId: widget.flatId,
        category: _category!,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint submitted')));
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
      appBar: AppBar(title: const Text('Raise a complaint')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('How can we help you?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Describe the issue in detail so our maintenance team can resolve it quickly.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Complaint category'),
              items: _categories.map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2))).toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Short title', hintText: 'e.g. Leaking tap in master bathroom'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description', hintText: 'Provide more details about the issue...'),
              maxLines: 5,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: const Text('Submit complaint'),
            ),
            const SizedBox(height: 8),
            const Text('Tickets are usually responded to within 24 hours.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
