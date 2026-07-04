import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../login_screen.dart';
import 'generate_bills_screen.dart';
import 'defaulter_list_screen.dart';
import 'document_upload_screen.dart';
import 'notices_composer_screen.dart';
import 'ai_secretary_screen.dart';

class AdminMoreScreen extends StatelessWidget {
  final int societyId;
  final String societyName;

  const AdminMoreScreen({super.key, required this.societyId, required this.societyName});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.smart_toy_outlined, 'AI Secretary assistant', () => AiSecretaryScreen(societyId: societyId, societyName: societyName)),
      (Icons.receipt_long_outlined, 'Generate bills', () => GenerateBillsScreen(societyId: societyId)),
      (Icons.warning_amber_outlined, 'Defaulter list', () => DefaulterListScreen(societyId: societyId)),
      (Icons.campaign_outlined, 'Notices composer', () => NoticesComposerScreen(societyId: societyId)),
      (Icons.upload_file_outlined, 'Document upload', () => DocumentUploadScreen(societyId: societyId)),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                for (final item in items) ...[
                  ListTile(
                    leading: Icon(item.$1),
                    title: Text(item.$2),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => item.$3()),
                    ),
                  ),
                  if (item != items.last) const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await ApiClient.clearToken();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
