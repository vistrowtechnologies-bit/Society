import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';
import 'notice_detail_screen.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
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
      final notices = await ApiClient.notices(flats.first['society_id']);
      setState(() {
        _notices = notices;
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
      appBar: AppBar(title: const Text('Society notices')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _notices.isEmpty
                  ? const Center(child: Text('No notices yet', style: TextStyle(color: AppColors.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notices.length,
                        itemBuilder: (context, i) {
                          final n = _notices[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                                child: const Icon(Icons.campaign, color: AppColors.accent, size: 18),
                              ),
                              title: Text(n['title']),
                              subtitle: Text(n['category'], style: const TextStyle(fontSize: 11, letterSpacing: 0.5)),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => NoticeDetailScreen(noticeId: n['id'])),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
