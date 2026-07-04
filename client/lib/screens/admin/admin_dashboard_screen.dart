import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';
import 'notices_composer_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final int societyId;
  final String societyName;

  const AdminDashboardScreen({super.key, required this.societyId, required this.societyName});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _summary;
  List<dynamic> _defaulters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final summary = await ApiClient.adminDashboard(widget.societyId);
    final defaulters = await ApiClient.defaulters(widget.societyId);
    setState(() {
      _summary = summary;
      _defaulters = defaulters.take(3).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard overview')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Morning, Secretary', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text("Here's what's happening at ${widget.societyName} today.",
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => NoticesComposerScreen(societyId: widget.societyId)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Post announcement'),
                  ),
                  const SizedBox(height: 16),
                  _metricCard(
                    'Collection this month',
                    '${_summary!['collection_percent']}%',
                    Icons.payments_outlined,
                    progress: (_summary!['collection_percent'] as num) / 100,
                  ),
                  const SizedBox(height: 12),
                  _metricCard(
                    'Total dues',
                    '₹${_summary!['total_dues']}',
                    Icons.account_balance_wallet_outlined,
                    subtitle: '${_summary!['defaulters_count']} defaulters',
                    subtitleColor: AppColors.danger,
                  ),
                  const SizedBox(height: 12),
                  _metricCard(
                    'Open complaints',
                    '${_summary!['open_complaints_count']}',
                    Icons.report_problem_outlined,
                    subtitle: '${_summary!['urgent_complaints_count']} urgent',
                    subtitleColor: AppColors.danger,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Defaulters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_defaulters.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No defaulters right now', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  else
                    Card(
                      child: Column(
                        children: _defaulters.map((b) {
                          final due = (b['amount'] as num) + (b['late_fee'] as num) - (b['amount_paid'] as num);
                          return ListTile(
                            title: Text('Flat #${b['flat_id']}'),
                            subtitle: Text('Due ${b['due_date']}'),
                            trailing: Text('₹${due.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, {double? progress, String? subtitle, Color? subtitleColor}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Icon(icon, size: 18, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: subtitleColor ?? AppColors.textSecondary, fontSize: 12)),
            ],
            if (progress != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
