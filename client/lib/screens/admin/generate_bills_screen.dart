import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class GenerateBillsScreen extends StatefulWidget {
  final int societyId;

  const GenerateBillsScreen({super.key, required this.societyId});

  @override
  State<GenerateBillsScreen> createState() => _GenerateBillsScreenState();
}

class _GenerateBillsScreenState extends State<GenerateBillsScreen> {
  final _amountController = TextEditingController(text: '2500');
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 10));
  bool _loading = false;
  List<dynamic>? _created;
  String? _error;

  Future<void> _generate() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount greater than zero');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _created = null;
    });
    try {
      final created = await ApiClient.generateBillsForSociety(
        societyId: widget.societyId,
        month: _month,
        year: _year,
        amountPerFlat: amount,
        dueDate: _dueDate.toIso8601String().split('T').first,
      );
      setState(() => _created = created);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Initiate monthly billing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _month,
                    decoration: const InputDecoration(labelText: 'Month'),
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(value: m, child: Text(m.toString())))
                        .toList(),
                    onChanged: (v) => setState(() => _month = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _year,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items: [_year, _year + 1].map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                    onChanged: (v) => setState(() => _year = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount per flat'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Due date'),
              subtitle: Text(_dueDate.toIso8601String().split('T').first),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _generate,
              child: _loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Generate bills'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            if (_created != null) ...[
              const SizedBox(height: 20),
              const Text('Execution summary', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('${_created!.length} new bills generated for $_month/$_year.'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
