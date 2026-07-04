import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';

class NoticeDetailScreen extends StatefulWidget {
  final int noticeId;

  const NoticeDetailScreen({super.key, required this.noticeId});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  Map<String, dynamic>? _notice;

  @override
  void initState() {
    super.initState();
    ApiClient.notice(widget.noticeId).then((n) => setState(() => _notice = n));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notice')),
      body: _notice == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(_notice!['category'], style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                  ),
                  const SizedBox(height: 12),
                  Text(_notice!['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(_notice!['created_at'].toString().split('T').first, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 16),
                  Text(_notice!['body'], style: const TextStyle(fontSize: 15, height: 1.5)),
                ],
              ),
            ),
    );
  }
}
