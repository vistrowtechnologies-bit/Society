import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'member_management_screen.dart';
import 'complaints_management_screen.dart';
import 'admin_more_screen.dart';

class AdminShell extends StatefulWidget {
  final int societyId;
  final String societyName;

  const AdminShell({super.key, required this.societyId, required this.societyName});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      AdminDashboardScreen(societyId: widget.societyId, societyName: widget.societyName),
      MemberManagementScreen(societyId: widget.societyId),
      ComplaintsManagementScreen(societyId: widget.societyId),
      AdminMoreScreen(societyId: widget.societyId, societyName: widget.societyName),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Members'),
          BottomNavigationBarItem(icon: Icon(Icons.report_problem_outlined), activeIcon: Icon(Icons.report_problem), label: 'Complaints'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }
}
