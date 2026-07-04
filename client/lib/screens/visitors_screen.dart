import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';

class VisitorsScreen extends StatefulWidget {
  final int flatId;

  const VisitorsScreen({super.key, required this.flatId});

  @override
  State<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends State<VisitorsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _purpose = 'guest';
  List<dynamic> _visitors = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  final _purposes = const ['guest', 'delivery', 'cab', 'service', 'other'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final visitors = await ApiClient.flatVisitors(widget.flatId);
    setState(() {
      _visitors = visitors;
      _loading = false;
    });
  }

  Future<void> _preApprove() async {
    if (_nameController.text.isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ApiClient.preApproveVisitor(
        flatId: widget.flatId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        purpose: _purpose,
      );
      _nameController.clear();
      _phoneController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visitor pre-approved')));
      _load();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visitors')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Pre-approve a visitor', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
                    const SizedBox(height: 10),
                    TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone (optional)')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _purpose,
                      decoration: const InputDecoration(labelText: 'Purpose'),
                      items: _purposes.map((p) => DropdownMenuItem(value: p, child: Text(p[0].toUpperCase() + p.substring(1)))).toList(),
                      onChanged: (v) => setState(() => _purpose = v!),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: AppColors.danger)),
                    ],
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _submitting ? null : _preApprove,
                      child: _submitting
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Pre-approve'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Recent visitors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
            else if (_visitors.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('No visitors yet', style: TextStyle(color: AppColors.textSecondary)))
            else
              ..._visitors.map((v) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(v['name']),
                      subtitle: Text('${v['purpose']} · ${v['created_at'].toString().split('T').first}'),
                      trailing: StatusBadge.forStatus(v['status']),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
