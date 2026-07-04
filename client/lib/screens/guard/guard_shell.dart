import 'package:flutter/material.dart';
import 'guard_visitors_screen.dart';
import 'guard_staff_screen.dart';
import 'guard_sos_screen.dart';
import '../../api_client.dart';
import '../login_screen.dart';

class GuardShell extends StatefulWidget {
  final int societyId;
  final String societyName;

  const GuardShell({super.key, required this.societyId, required this.societyName});

  @override
  State<GuardShell> createState() => _GuardShellState();
}

class _GuardShellState extends State<GuardShell> {
  int _index = 0;

  Future<void> _logout() async {
    await ApiClient.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      GuardVisitorsScreen(societyId: widget.societyId),
      GuardStaffScreen(societyId: widget.societyId),
      GuardSosScreen(societyId: widget.societyId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.societyName} · Gate'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: 'Visitors'),
          BottomNavigationBarItem(icon: Icon(Icons.badge_outlined), activeIcon: Icon(Icons.badge), label: 'Staff'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_amber_outlined), activeIcon: Icon(Icons.warning), label: 'SOS'),
        ],
      ),
    );
  }
}
