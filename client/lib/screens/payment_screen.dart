import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';
import 'payment_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> bill;
  final double amountDue;

  const PaymentScreen({super.key, required this.bill, required this.amountDue});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'upi';
  bool _loading = false;
  String? _error;

  final _methods = const [
    ('upi', 'UPI', Icons.qr_code),
    ('bank_transfer', 'Bank transfer', Icons.account_balance),
    ('cheque', 'Cheque', Icons.receipt_long),
  ];

  Future<void> _pay() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiClient.recordPayment(widget.bill['id'], widget.amountDue, _method);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PaymentSuccessScreen(amount: widget.amountDue)),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
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
                    const Text('Amount to pay', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('₹${widget.amountDue.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Select payment method', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._methods.map((m) {
              final selected = _method == m.$1;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 0.5),
                ),
                child: RadioListTile<String>(
                  value: m.$1,
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v!),
                  title: Row(
                    children: [
                      Icon(m.$3, size: 20),
                      const SizedBox(width: 10),
                      Text(m.$2),
                    ],
                  ),
                ),
              );
            }),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const Spacer(),
            FilledButton(
              onPressed: _loading ? null : _pay,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm payment'),
            ),
          ],
        ),
      ),
    );
  }
}
