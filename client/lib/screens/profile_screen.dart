import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'my_complaints_screen.dart';
import 'vehicles_screen.dart';
import 'staff_screen.dart';
import 'amenities_screen.dart';
import 'polls_screen.dart';
import 'sos_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _flat;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await ApiClient.me();
    final flats = await ApiClient.myFlats();
    setState(() {
      _user = user;
      _flat = flats.isNotEmpty ? flats.first : null;
    });
  }

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
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(radius: 44, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white, size: 40)),
                      const SizedBox(height: 12),
                      Text(_user!['full_name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      if (_flat != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('${_flat!['tower_name']}, ${_flat!['flat_number']}', style: const TextStyle(color: AppColors.textSecondary)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: const Text('Mobile', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    subtitle: Text(_user!['phone'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.mail_outline),
                    title: const Text('Email', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    subtitle: Text(_user!['email'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
                if (_flat != null)
                  Card(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    child: ListTile(
                      leading: const Icon(Icons.warning_rounded, color: AppColors.danger),
                      title: const Text('Emergency SOS', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Alert security immediately'),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.danger),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SosScreen(flatId: _flat!['flat_id'])),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.report_problem_outlined),
                        title: const Text('My complaints'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MyComplaintsScreen()),
                        ),
                      ),
                      if (_flat != null) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.directions_car_outlined),
                          title: const Text('My vehicles'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => VehiclesScreen(flatId: _flat!['flat_id'])),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.badge_outlined),
                          title: const Text('Domestic staff'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => StaffScreen(flatId: _flat!['flat_id'])),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.villa_outlined),
                          title: const Text('Amenities'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => AmenitiesScreen(societyId: _flat!['society_id'], flatId: _flat!['flat_id'])),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.poll_outlined),
                          title: const Text('Society polls'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => PollsScreen(societyId: _flat!['society_id'])),
                          ),
                        ),
                      ],
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.notifications_outlined),
                        title: Text('Notification settings'),
                        trailing: Icon(Icons.chevron_right),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('About SocietyOS'),
                        trailing: Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger, width: 0.5),
                  ),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text('Powered by SocietyOS Labs', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
              ],
            ),
    );
  }
}
