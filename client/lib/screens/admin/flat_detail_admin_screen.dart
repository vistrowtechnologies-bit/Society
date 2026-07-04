import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class FlatDetailAdminScreen extends StatefulWidget {
  final Map<String, dynamic> entry;

  const FlatDetailAdminScreen({super.key, required this.entry});

  @override
  State<FlatDetailAdminScreen> createState() => _FlatDetailAdminScreenState();
}

class _FlatDetailAdminScreenState extends State<FlatDetailAdminScreen> {
  List<dynamic> _bills = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bills = await ApiClient.billsForFlat(widget.entry['flat_id']);
    bills.sort((a, b) => (b['period_year'] * 100 + b['period_month']).compareTo(a['period_year'] * 100 + a['period_month']));
    setState(() {
      _bills = bills;
      _loading = false;
    });
  }

  Future<void> _confirmDelete(int billId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this bill?'),
        content: const Text('This permanently removes the bill. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel bill')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.deleteBill(billId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill cancelled')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return Scaffold(
      appBar: AppBar(title: Text('Flat ${e['flat_number']}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['resident_name'] ?? 'Unassigned', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('${e['tower_name']}, Flat ${e['flat_number']}', style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text('Relation: ${e['relation'] ?? '—'}', style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Billing history', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ..._bills.map((bill) {
                  final due = (bill['amount'] as num) + (bill['late_fee'] as num) - (bill['amount_paid'] as num);
                  final isPaid = bill['status'] == 'paid' || (bill['amount_paid'] as num) > 0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text('${bill['period_month']}/${bill['period_year']} — ₹${bill['amount']}'),
                      subtitle: Text('Due ${bill['due_date']} · balance ₹${due.toStringAsFixed(0)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusBadge.forStatus(bill['status']),
                          // Only unpaid bills can be cancelled (paid bills are protected server-side too).
                          if (!isPaid)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              tooltip: 'Cancel bill',
                              onPressed: () => _confirmDelete(bill['id']),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
