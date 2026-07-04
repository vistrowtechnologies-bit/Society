import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class AdminSosScreen extends StatefulWidget {
  final int societyId;

  const AdminSosScreen({super.key, required this.societyId});

  @override
  State<AdminSosScreen> createState() => _AdminSosScreenState();
}

class _AdminSosScreenState extends State<AdminSosScreen> {
  List<dynamic> _alerts = [];
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
      final alerts = await ApiClient.societySOSAlerts(widget.societyId, activeOnly: false);
      setState(() {
        _alerts = alerts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _resolve(int id) async {
    await ApiClient.resolveSOS(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS alerts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
              : _alerts.isEmpty
              ? const Center(child: Text('No alerts', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length,
                    itemBuilder: (context, i) {
                      final a = _alerts[i];
                      final active = a['status'] == 'active';
                      return Card(
                        color: active ? AppColors.danger.withValues(alpha: 0.06) : null,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(active ? Icons.warning_rounded : Icons.check_circle,
                              color: active ? AppColors.danger : AppColors.success),
                          title: Text('Flat #${a['flat_id']}'),
                          subtitle: Text(a['message'] ?? 'Emergency alert'),
                          trailing: active
                              ? FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                                  onPressed: () => _resolve(a['id']),
                                  child: const Text('Resolve'),
                                )
                              : StatusBadge.forStatus(a['status']),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
