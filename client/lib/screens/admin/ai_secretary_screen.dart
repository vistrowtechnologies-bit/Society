import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class AiSecretaryScreen extends StatefulWidget {
  final int societyId;
  final String societyName;

  const AiSecretaryScreen({super.key, required this.societyId, required this.societyName});

  @override
  State<AiSecretaryScreen> createState() => _AiSecretaryScreenState();
}

class _AiSecretaryScreenState extends State<AiSecretaryScreen> {
  final _promptController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _loading = false;
  bool _hasDraft = false;
  String? _error;

  Future<void> _generate() async {
    if (_promptController.text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final draft = await ApiClient.generateNoticeDraft(
        prompt: _promptController.text.trim(),
        societyName: widget.societyName,
      );
      setState(() {
        _titleController.text = draft['title'];
        _bodyController.text = draft['body'];
        _hasDraft = true;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendToResidents() async {
    setState(() => _loading = true);
    try {
      await ApiClient.createNotice(
        societyId: widget.societyId,
        category: 'General',
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sent to residents')));
      setState(() {
        _hasDraft = false;
        _promptController.clear();
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Secretary')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _hasDraft
                  ? SingleChildScrollView(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                child: const Text('DRAFT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _titleController,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                maxLines: null,
                              ),
                              const Divider(height: 20),
                              TextField(
                                controller: _bodyController,
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                maxLines: null,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _loading ? null : _sendToResidents,
                                icon: const Icon(Icons.send),
                                label: const Text('Send to residents'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        'Ask me to draft an AGM notice, circular, or announcement.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
            ),
            if (_error != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(hintText: 'e.g. Prepare AGM notice for 15 Aug'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _loading ? null : _generate,
                  icon: _loading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
