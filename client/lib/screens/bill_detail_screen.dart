import 'package:flutter/material.dart';
import '../theme.dart';
import 'payment_screen.dart';

class BillDetailScreen extends StatelessWidget {
  final Map<String, dynamic> bill;

  const BillDetailScreen({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final amount = bill['amount'] as num;
    final lateFee = bill['late_fee'] as num;
    final paid = bill['amount_paid'] as num;
    final due = amount + lateFee - paid;
    final isPaid = bill['status'] == 'paid';

    return Scaffold(
      appBar: AppBar(title: const Text('Bill details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('₹${due.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    StatusBadge.forStatus(bill['status']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Period', '${bill['period_month']}/${bill['period_year']}'),
                    const Divider(height: 20),
                    _row('Base maintenance', '₹${amount.toStringAsFixed(0)}'),
                    const Divider(height: 20),
                    _row('Late fee', '₹${lateFee.toStringAsFixed(0)}'),
                    const Divider(height: 20),
                    _row('Already paid', '₹${paid.toStringAsFixed(0)}'),
                    const Divider(height: 20),
                    _row('Due date', bill['due_date']),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (!isPaid)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PaymentScreen(bill: bill, amountDue: due.toDouble())),
                ),
                child: const Text('Pay now'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
