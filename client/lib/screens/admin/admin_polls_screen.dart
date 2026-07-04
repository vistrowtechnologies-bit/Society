import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class AdminPollsScreen extends StatefulWidget {
  final int societyId;

  const AdminPollsScreen({super.key, required this.societyId});

  @override
  State<AdminPollsScreen> createState() => _AdminPollsScreenState();
}

class _AdminPollsScreenState extends State<AdminPollsScreen> {
  List<dynamic> _polls = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final polls = await ApiClient.polls(widget.societyId);
    setState(() {
      _polls = polls;
      _loading = false;
    });
  }

  Future<void> _showCreateDialog() async {
    final questionController = TextEditingController();
    final optionControllers = [TextEditingController(), TextEditingController()];
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New poll'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: questionController, decoration: const InputDecoration(labelText: 'Question')),
                const SizedBox(height: 12),
                ...optionControllers.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: e.value,
                        decoration: InputDecoration(labelText: 'Option ${e.key + 1}'),
                      ),
                    )),
                TextButton.icon(
                  onPressed: () => setDialogState(() => optionControllers.add(TextEditingController())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add option'),
                ),
                if (error != null) Text(error!, style: const TextStyle(color: AppColors.danger)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final options = optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                if (questionController.text.isEmpty || options.length < 2) {
                  setDialogState(() => error = 'Enter a question and at least 2 options');
                  return;
                }
                try {
                  await ApiClient.createPoll(societyId: widget.societyId, question: questionController.text.trim(), options: options);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  setDialogState(() => error = e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Polls')),
      floatingActionButton: FloatingActionButton(onPressed: _showCreateDialog, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _polls.isEmpty
              ? const Center(child: Text('No polls yet', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _polls.length,
                    itemBuilder: (context, i) {
                      final poll = _polls[i];
                      final options = poll['options'] as List<dynamic>;
                      final total = options.fold<int>(0, (s, o) => s + (o['vote_count'] as int));
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(poll['question'], style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              ...options.map((o) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text('${o['text']}: ${o['vote_count']} vote${o['vote_count'] == 1 ? '' : 's'}',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  )),
                              const SizedBox(height: 4),
                              Text('Total: $total', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
