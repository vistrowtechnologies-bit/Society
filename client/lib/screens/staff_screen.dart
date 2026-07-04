import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';

class StaffScreen extends StatefulWidget {
  final int flatId;

  const StaffScreen({super.key, required this.flatId});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<dynamic> _staff = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final society = await ApiClient.me();
    final all = society['society_id'] != null ? await ApiClient.societyStaff(society['society_id']) : [];
    setState(() {
      _staff = all.where((s) => s['flat_id'] == widget.flatId).toList();
      _loading = false;
    });
  }

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String role = 'maid';
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add domestic staff'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 10),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'maid', child: Text('Maid')),
                  DropdownMenuItem(value: 'driver', child: Text('Driver')),
                  DropdownMenuItem(value: 'cook', child: Text('Cook')),
                  DropdownMenuItem(value: 'nanny', child: Text('Nanny')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setDialogState(() => role = v!),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: AppColors.danger)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                try {
                  await ApiClient.addStaff(
                    flatId: widget.flatId,
                    fullName: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    role: role,
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  setDialogState(() => error = e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Domestic staff')),
      floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _staff.isEmpty
              ? const Center(child: Text('No staff registered yet', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _staff.length,
                    itemBuilder: (context, i) {
                      final s = _staff[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.badge_outlined),
                          title: Text(s['full_name']),
                          subtitle: Text('${s['role']} · ${s['phone'] ?? 'no phone'}'),
                          trailing: s['is_verified']
                              ? const Icon(Icons.verified, color: AppColors.success, size: 20)
                              : const Text('Pending', style: TextStyle(color: AppColors.warning, fontSize: 12)),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
