import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class GuardVisitorsScreen extends StatefulWidget {
  final int societyId;

  const GuardVisitorsScreen({super.key, required this.societyId});

  @override
  State<GuardVisitorsScreen> createState() => _GuardVisitorsScreenState();
}

class _GuardVisitorsScreenState extends State<GuardVisitorsScreen> {
  List<dynamic> _visitors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final visitors = await ApiClient.societyVisitors(widget.societyId);
    setState(() {
      _visitors = visitors;
      _loading = false;
    });
  }

  Future<void> _updateStatus(int id, String status) async {
    await ApiClient.updateVisitorStatus(id, status);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _visitors.isEmpty
              ? ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: Text('No visitors today', style: TextStyle(color: AppColors.textSecondary))),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _visitors.length,
                  itemBuilder: (context, i) {
                    final v = _visitors[i];
                    final status = v['status'] as String;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(v['name']),
                        subtitle: Text('Flat #${v['flat_id']} · ${v['purpose']}'),
                        trailing: status == 'approved' || status == 'pending'
                            ? FilledButton(
                                onPressed: () => _updateStatus(v['id'], 'checked_in'),
                                child: const Text('Check in'),
                              )
                            : status == 'checked_in'
                                ? OutlinedButton(
                                    onPressed: () => _updateStatus(v['id'], 'checked_out'),
                                    child: const Text('Check out'),
                                  )
                                : StatusBadge.forStatus(status),
                      ),
                    );
                  },
                ),
    );
  }
}
