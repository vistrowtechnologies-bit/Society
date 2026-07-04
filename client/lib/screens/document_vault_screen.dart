import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';

class DocumentVaultScreen extends StatefulWidget {
  final int societyId;

  const DocumentVaultScreen({super.key, required this.societyId});

  @override
  State<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends State<DocumentVaultScreen> {
  List<dynamic> _documents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docs = await ApiClient.documents(widget.societyId);
    setState(() {
      _documents = docs;
      _loading = false;
    });
  }

  Map<String, List<dynamic>> get _byCategory {
    final map = <String, List<dynamic>>{};
    for (final d in _documents) {
      map.putIfAbsent(d['category'], () => []).add(d);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document vault')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? const Center(child: Text('No documents uploaded yet', style: TextStyle(color: AppColors.textSecondary)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _byCategory.entries.map((entry) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                            child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          ...entry.value.map((d) => ListTile(
                                leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                                title: Text(d['title']),
                                subtitle: Text(d['uploaded_at'].toString().split('T').first),
                              )),
                        ],
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
