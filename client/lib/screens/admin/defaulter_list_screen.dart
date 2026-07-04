import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class DefaulterListScreen extends StatefulWidget {
  final int societyId;

  const DefaulterListScreen({super.key, required this.societyId});

  @override
  State<DefaulterListScreen> createState() => _DefaulterListScreenState();
}

class _DefaulterListScreenState extends State<DefaulterListScreen> {
  List<dynamic> _defaulters = [];
  bool _loading = true;
  String _sort = 'days';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final defaulters = await ApiClient.defaulters(widget.societyId);
    setState(() {
      _defaulters = defaulters;
      _loading = false;
      _applySort();
    });
  }

  void _applySort() {
    if (_sort == 'amount') {
      _defaulters.sort((a, b) {
        final dueA = (a['amount'] as num) + (a['late_fee'] as num) - (a['amount_paid'] as num);
        final dueB = (b['amount'] as num) + (b['late_fee'] as num) - (b['amount_paid'] as num);
        return dueB.compareTo(dueA);
      });
    } else if (_sort == 'flat') {
      _defaulters.sort((a, b) => a['flat_id'].compareTo(b['flat_id']));
    } else {
      _defaulters.sort((a, b) => a['due_date'].compareTo(b['due_date']));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Defaulter list'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() {
              _sort = v;
              _applySort();
            }),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'days', child: Text('Sort by days overdue')),
              PopupMenuItem(value: 'amount', child: Text('Sort by amount')),
              PopupMenuItem(value: 'flat', child: Text('Sort by flat number')),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _defaulters.isEmpty
              ? const Center(child: Text('No defaulters right now', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _defaulters.length,
                    itemBuilder: (context, i) {
                      final b = _defaulters[i];
                      final due = (b['amount'] as num) + (b['late_fee'] as num) - (b['amount_paid'] as num);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.warning_amber_outlined, color: AppColors.danger),
                          title: Text('Flat #${b['flat_id']}'),
                          subtitle: Text('Due since ${b['due_date']}'),
                          trailing: Text('₹${due.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
