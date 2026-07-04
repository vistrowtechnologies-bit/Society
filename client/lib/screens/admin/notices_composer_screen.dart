import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class NoticesComposerScreen extends StatefulWidget {
  final int societyId;
  final String? initialTitle;
  final String? initialBody;

  const NoticesComposerScreen({super.key, required this.societyId, this.initialTitle, this.initialBody});

  @override
  State<NoticesComposerScreen> createState() => _NoticesComposerScreenState();
}

class _NoticesComposerScreenState extends State<NoticesComposerScreen> {
  late final _titleController = TextEditingController(text: widget.initialTitle ?? '');
  late final _bodyController = TextEditingController(text: widget.initialBody ?? '');
  String _category = 'General';
  bool _loading = false;
  String? _error;

  final _categories = const ['General', 'AGM', 'Maintenance', 'Security', 'Amenities'];

  Future<void> _publish() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiClient.createNotice(
        societyId: widget.societyId,
        category: _category,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice posted')));
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
      appBar: AppBar(title: const Text('Post new notice')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Annual General Body Meeting 2026'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: 'Body', hintText: 'Write your announcement details here...'),
              maxLines: 8,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Target audience / category'),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loading ? null : _publish,
              icon: _loading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }
}
