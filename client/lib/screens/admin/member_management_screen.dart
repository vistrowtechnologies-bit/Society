import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';
import 'flat_detail_admin_screen.dart';

class MemberManagementScreen extends StatefulWidget {
  final int societyId;

  const MemberManagementScreen({super.key, required this.societyId});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  List<dynamic> _directory = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final directory = await ApiClient.directory(widget.societyId);
    setState(() {
      _directory = directory;
      _loading = false;
    });
  }

  List<dynamic> get _filtered {
    if (_query.isEmpty) return _directory;
    final q = _query.toLowerCase();
    return _directory.where((d) {
      final name = (d['resident_name'] ?? '').toString().toLowerCase();
      final flat = d['flat_number'].toString().toLowerCase();
      return name.contains(q) || flat.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resident directory')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search by name or flat number',
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final d = _filtered[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(d['resident_name'] ?? 'Unassigned'),
                            subtitle: Text('${d['tower_name']}, Flat ${d['flat_number']} · ${d['relation'] ?? '—'}'),
                            trailing: (d['outstanding_dues'] as num) > 0
                                ? Text('₹${d['outstanding_dues']}', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600))
                                : const Icon(Icons.check_circle, color: AppColors.success),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => FlatDetailAdminScreen(entry: d)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
