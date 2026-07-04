import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class GuardStaffScreen extends StatefulWidget {
  final int societyId;

  const GuardStaffScreen({super.key, required this.societyId});

  @override
  State<GuardStaffScreen> createState() => _GuardStaffScreenState();
}

class _GuardStaffScreenState extends State<GuardStaffScreen> {
  List<dynamic> _staff = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final staff = await ApiClient.societyStaff(widget.societyId);
      setState(() {
        _staff = staff;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _checkIn(int id) async {
    try {
      await ApiClient.staffCheckIn(id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _checkOut(int id) async {
    try {
      await ApiClient.staffCheckOut(id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(
                  children: [
                    Padding(padding: const EdgeInsets.only(top: 80), child: Center(child: Text(_error!, textAlign: TextAlign.center))),
                  ],
                )
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _staff.length,
              itemBuilder: (context, i) {
                final s = _staff[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(s['is_verified'] ? Icons.verified : Icons.badge_outlined,
                        color: s['is_verified'] ? AppColors.success : AppColors.textMuted),
                    title: Text(s['full_name']),
                    subtitle: Text('${s['role']} · Flat #${s['flat_id'] ?? '—'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.login, size: 20, color: AppColors.success),
                          tooltip: 'Check in',
                          onPressed: () => _checkIn(s['id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, size: 20, color: AppColors.textSecondary),
                          tooltip: 'Check out',
                          onPressed: () => _checkOut(s['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
