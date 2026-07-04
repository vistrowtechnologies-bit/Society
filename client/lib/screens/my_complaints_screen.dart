import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  List<dynamic> _complaints = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final complaints = await ApiClient.myComplaints();
    setState(() {
      _complaints = complaints;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My complaints')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _complaints.isEmpty
              ? const Center(child: Text('No complaints raised yet', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _complaints.length,
                    itemBuilder: (context, i) {
                      final c = _complaints[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(c['title']),
                          subtitle: Text('${c['category']} · ${c['updated_at'].toString().split('T').first}'),
                          trailing: StatusBadge.forStatus(c['status']),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
