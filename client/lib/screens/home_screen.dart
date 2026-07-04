import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';
import 'bill_detail_screen.dart';
import 'raise_complaint_screen.dart';
import 'document_vault_screen.dart';
import 'notice_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _flat;
  Map<String, dynamic>? _currentBill;
  List<dynamic> _notices = [];
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
      final flat = flats.first;
      final bills = await ApiClient.billsForFlat(flat['flat_id']);
      final pending = bills.where((b) => b['status'] != 'paid').toList();
      final notices = await ApiClient.notices(flat['society_id']);
      setState(() {
        _flat = flat;
        _currentBill = pending.isNotEmpty ? pending.first : null;
        _notices = notices.take(3).toList();
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
      appBar: AppBar(title: const Text('SocietyOS')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.apartment, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_flat!['society_name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  Text('Flat ${_flat!['flat_number']}, ${_flat!['tower_name']}', style: const TextStyle(color: AppColors.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_currentBill != null) _billCard() else _noDuesCard(),
                      const SizedBox(height: 16),
                      _quickActions(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Recent notices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_notices.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('No notices yet', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      else
                        Card(
                          child: Column(
                            children: _notices.map((n) {
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                                  child: const Icon(Icons.campaign, color: AppColors.accent, size: 18),
                                ),
                                title: Text(n['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(n['category'], style: const TextStyle(fontSize: 11)),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => NoticeDetailScreen(noticeId: n['id'])),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _billCard() {
    final due = (_currentBill!['amount'] as num) + (_currentBill!['late_fee'] as num) - (_currentBill!['amount_paid'] as num);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CURRENT BILL', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 0.5)),
                StatusBadge.forStatus(_currentBill!['status']),
              ],
            ),
            const SizedBox(height: 8),
            Text('Maintenance due: ₹${due.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.textPrimary),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Pay now'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BillDetailScreen(bill: _currentBill!)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noDuesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: const [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 12),
            Text('All bills paid up. Nothing due right now.'),
          ],
        ),
      ),
    );
  }

  Widget _quickActions() {
    final actions = [
      (Icons.receipt_long_outlined, 'Pay', () {}),
      (Icons.report_problem_outlined, 'Complaints', () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => RaiseComplaintScreen(flatId: _flat!['flat_id'])));
      }),
      (Icons.folder_outlined, 'Docs', () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocumentVaultScreen(societyId: _flat!['society_id'])));
      }),
      (Icons.groups_outlined, 'Visitors', () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visitor management coming soon')));
      }),
    ];
    return Row(
      children: actions.map((a) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: a.$3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      Icon(a.$1, color: AppColors.textPrimary),
                      const SizedBox(height: 6),
                      Text(a.$2, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
