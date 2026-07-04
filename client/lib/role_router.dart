import 'package:flutter/material.dart';
import 'api_client.dart';
import 'screens/main_shell.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/guard/guard_shell.dart';

const _adminRoles = {'admin', 'secretary', 'treasurer', 'committee'};

Future<void> routeAfterAuth(BuildContext context) async {
  final user = await ApiClient.me();
  final role = user['role'] as String;

  Widget destination;
  if ((_adminRoles.contains(role) || role == 'guard') && user['society_id'] != null) {
    final society = await ApiClient.listSocieties();
    final match = society.firstWhere(
      (s) => s['id'] == user['society_id'],
      orElse: () => {'name': 'SocietyOS'},
    );
    destination = role == 'guard'
        ? GuardShell(societyId: user['society_id'], societyName: match['name'])
        : AdminShell(societyId: user['society_id'], societyName: match['name']);
  } else {
    destination = const MainShell();
  }

  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => destination),
    (route) => false,
  );
}
