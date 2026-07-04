import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final int flatId;

  const PaymentHistoryScreen({super.key, required this.flatId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<dynamic> _bills = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bills = await ApiClient.billsForFlat(widget.flatId);
    bills.sort((a, b) => (b['period_year'] * 100 + b['period_month']).compareTo(a['period_year'] * 100 + a['period_month']));
    setState(() {
      _bills = bills;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment history')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bills.length,
              itemBuilder: (context, i) {
                final bill = _bills[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(
                      bill['status'] == 'paid' ? Icons.check_circle : Icons.schedule,
                      color: bill['status'] == 'paid' ? AppColors.success : AppColors.textMuted,
                    ),
                    title: Text('${bill['period_month']}/${bill['period_year']}'),
                    subtitle: Text('₹${bill['amount']} · paid ₹${bill['amount_paid']}'),
                    trailing: StatusBadge.forStatus(bill['status']),
                  ),
                );
              },
            ),
    );
  }
}
