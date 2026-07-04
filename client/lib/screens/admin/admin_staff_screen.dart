import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class AdminStaffScreen extends StatefulWidget {
  final int societyId;

  const AdminStaffScreen({super.key, required this.societyId});

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  List<dynamic> _staff = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final staff = await ApiClient.societyStaff(widget.societyId);
    setState(() {
      _staff = staff;
      _loading = false;
    });
  }

  Future<void> _toggleVerify(int id, bool current) async {
    await ApiClient.verifyStaff(id, !current);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff directory')),
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
                          subtitle: Text('${s['role']} · Flat #${s['flat_id'] ?? '—'}'),
                          trailing: FilterChip(
                            label: Text(s['is_verified'] ? 'Verified' : 'Verify'),
                            selected: s['is_verified'],
                            selectedColor: AppColors.success.withValues(alpha: 0.15),
                            onSelected: (_) => _toggleVerify(s['id'], s['is_verified']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
