import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';

class SosScreen extends StatefulWidget {
  final int flatId;

  const SosScreen({super.key, required this.flatId});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final _messageController = TextEditingController();
  List<dynamic> _history = [];
  bool _loading = true;
  bool _sending = false;
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
      final history = await ApiClient.mySOSAlerts();
      setState(() {
        _history = history;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _confirmAndSend() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Raise emergency alert?'),
        content: const Text('This immediately notifies the security guard and society committee. Only use this in a real emergency.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send alert'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _sending = true);
    try {
      await ApiClient.raiseSOS(
        flatId: widget.flatId,
        message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
      );
      _messageController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert sent — security has been notified'), backgroundColor: AppColors.danger),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency SOS')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _sending ? null : _confirmAndSend,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                    child: _sending
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : const Icon(Icons.warning_rounded, color: Colors.white, size: 64),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Tap to alert security', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 6),
                const Text(
                  'Sends an immediate alert to your society\'s guard and committee',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(labelText: 'Optional details (e.g. what\'s happening)'),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          const Text('Past alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(_error!, textAlign: TextAlign.center))
          else if (_history.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('No past alerts', style: TextStyle(color: AppColors.textSecondary)))
          else
            ..._history.map((h) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(
                      h['status'] == 'resolved' ? Icons.check_circle : Icons.error,
                      color: h['status'] == 'resolved' ? AppColors.success : AppColors.danger,
                    ),
                    title: Text(h['message'] ?? 'Emergency alert'),
                    subtitle: Text(h['created_at'].toString().split('T').first),
                    trailing: StatusBadge.forStatus(h['status']),
                  ),
                )),
        ],
      ),
    );
  }
}
