import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class GuardSosScreen extends StatefulWidget {
  final int societyId;

  const GuardSosScreen({super.key, required this.societyId});

  @override
  State<GuardSosScreen> createState() => _GuardSosScreenState();
}

class _GuardSosScreenState extends State<GuardSosScreen> {
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
      final alerts = await ApiClient.societySOSAlerts(widget.societyId);
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
              : _alerts.isEmpty
              ? ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.success, size: 48),
                            SizedBox(height: 12),
                            Text('No active alerts', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _alerts.length,
                  itemBuilder: (context, i) {
                    final a = _alerts[i];
                    return Card(
                      color: AppColors.danger.withValues(alpha: 0.06),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.warning_rounded, color: AppColors.danger),
                        title: Text('Flat #${a['flat_id']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(a['message'] ?? 'Emergency alert'),
                        trailing: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                          onPressed: () => _resolve(a['id']),
                          child: const Text('Resolve'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
