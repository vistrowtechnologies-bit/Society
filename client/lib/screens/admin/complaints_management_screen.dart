import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class ComplaintsManagementScreen extends StatefulWidget {
  final int societyId;

  const ComplaintsManagementScreen({super.key, required this.societyId});

  @override
  State<ComplaintsManagementScreen> createState() => _ComplaintsManagementScreenState();
}

class _ComplaintsManagementScreenState extends State<ComplaintsManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _complaints = [];
  bool _loading = true;

  final _statuses = const ['open', 'in_progress', 'resolved'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final complaints = await ApiClient.societyComplaints(widget.societyId);
    setState(() {
      _complaints = complaints;
      _loading = false;
    });
  }

  Future<void> _updateStatus(int complaintId, String status) async {
    await ApiClient.updateComplaintStatus(complaintId, status);
    _load();
  }

  List<dynamic> _forStatus(String status) => _complaints.where((c) => c['status'] == status).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Open'), Tab(text: 'In progress'), Tab(text: 'Resolved')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _statuses.map((status) {
                final items = _forStatus(status);
                if (items.isEmpty) {
                  return const Center(child: Text('Nothing here', style: TextStyle(color: AppColors.textSecondary)));
                }
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final c = items[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(c['title']),
                          subtitle: Text('${c['category']} · flat #${c['flat_id']}'),
                          trailing: PopupMenuButton<String>(
                            initialValue: c['status'],
                            onSelected: (v) => _updateStatus(c['id'], v),
                            itemBuilder: (context) => _statuses
                                .map((s) => PopupMenuItem(value: s, child: Text(StatusBadge.forStatus(s).label)))
                                .toList(),
                            child: StatusBadge.forStatus(c['status']),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
    );
  }
}
