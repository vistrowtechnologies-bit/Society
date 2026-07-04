import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  List<dynamic> _societies = [];
  List<dynamic> _towers = [];
  List<dynamic> _flats = [];
  int? _societyId;
  int? _towerId;
  int? _flatId;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSocieties();
  }

  Future<void> _loadSocieties() async {
    try {
      final societies = await ApiClient.listSocieties();
      setState(() => _societies = societies);
    } catch (_) {}
  }

  Future<void> _loadTowers(int societyId) async {
    final towers = await ApiClient.listTowers(societyId);
    setState(() {
      _towers = towers;
      _towerId = null;
      _flats = [];
      _flatId = null;
    });
  }

  Future<void> _loadFlats(int towerId) async {
    final flats = await ApiClient.listFlats(towerId);
    setState(() {
      _flats = flats;
      _flatId = null;
    });
  }

  Future<void> _submit() async {
    if (_flatId == null || _societyId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ApiClient.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        societyId: _societyId,
      );
      final loginResult = await ApiClient.login(_emailController.text.trim(), _passwordController.text);
      await ApiClient.saveToken(loginResult['access_token']);
      await ApiClient.joinFlat(user['id'], _flatId!);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join SocietyOS')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _step == 0 ? _accountStep() : _societyStep(),
        ),
      ),
    );
  }

  Widget _accountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Create your account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full name')),
        const SizedBox(height: 12),
        TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 12),
        TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
        const SizedBox(height: 12),
        TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) return;
            setState(() => _step = 1);
          },
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _societyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Select your society', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          initialValue: _societyId,
          decoration: const InputDecoration(labelText: 'Society'),
          items: _societies
              .map<DropdownMenuItem<int>>((s) => DropdownMenuItem(value: s['id'], child: Text(s['name'])))
              .toList(),
          onChanged: (id) {
            setState(() => _societyId = id);
            if (id != null) _loadTowers(id);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _towerId,
          decoration: const InputDecoration(labelText: 'Tower'),
          items: _towers
              .map<DropdownMenuItem<int>>((t) => DropdownMenuItem(value: t['id'], child: Text(t['name'])))
              .toList(),
          onChanged: (id) {
            setState(() => _towerId = id);
            if (id != null) _loadFlats(id);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _flatId,
          decoration: const InputDecoration(labelText: 'Flat'),
          items: _flats
              .map<DropdownMenuItem<int>>((f) => DropdownMenuItem(value: f['id'], child: Text(f['number'])))
              .toList(),
          onChanged: (id) => setState(() => _flatId = id),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: (_loading || _flatId == null) ? null : _submit,
          child: _loading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Create account'),
        ),
      ],
    );
  }
}
