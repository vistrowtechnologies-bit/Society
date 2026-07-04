import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';
import 'bill_detail_screen.dart';
import 'payment_history_screen.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  List<dynamic> _bills = [];
  int? _flatId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final flats = await ApiClient.myFlats();
      if (flats.isEmpty) {
        setState(() {
          _error = 'No flat linked to your account yet.';
          _loading = false;
        });
        return;
      }
      final flatId = flats.first['flat_id'];
      final bills = await ApiClient.billsForFlat(flatId);
      bills.sort((a, b) => (b['period_year'] * 100 + b['period_month']).compareTo(a['period_year'] * 100 + a['period_month']));
      setState(() {
        _flatId = flatId;
        _bills = bills;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _flatId == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PaymentHistoryScreen(flatId: _flatId!)),
                    ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bills.length,
                    itemBuilder: (context, i) {
                      final bill = _bills[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text('${bill['period_month']}/${bill['period_year']} — ₹${bill['amount']}'),
                          subtitle: Text('Due ${bill['due_date']}'),
                          trailing: StatusBadge.forStatus(bill['status']),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => BillDetailScreen(bill: bill)),
                          ),
                          isThreeLine: false,
                          subtitleTextStyle: const TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
