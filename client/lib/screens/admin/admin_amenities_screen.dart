import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../theme.dart';

class AdminAmenitiesScreen extends StatefulWidget {
  final int societyId;

  const AdminAmenitiesScreen({super.key, required this.societyId});

  @override
  State<AdminAmenitiesScreen> createState() => _AdminAmenitiesScreenState();
}

class _AdminAmenitiesScreenState extends State<AdminAmenitiesScreen> {
  List<dynamic> _amenities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final amenities = await ApiClient.amenities(widget.societyId);
    setState(() {
      _amenities = amenities;
      _loading = false;
    });
  }

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    final capacityController = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add amenity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name (e.g. Clubhouse)')),
              const SizedBox(height: 10),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(labelText: 'Capacity (optional)'),
                keyboardType: TextInputType.number,
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: AppColors.danger)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                try {
                  await ApiClient.createAmenity(
                    name: nameController.text.trim(),
                    capacity: int.tryParse(capacityController.text.trim()),
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  setDialogState(() => error = e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(int id) async {
    await ApiClient.deleteAmenity(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Amenities')),
      floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _amenities.isEmpty
              ? const Center(child: Text('No amenities set up yet', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _amenities.length,
                    itemBuilder: (context, i) {
                      final a = _amenities[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.villa_outlined),
                          title: Text(a['name']),
                          subtitle: Text('${a['open_time']} - ${a['close_time']}${a['capacity'] != null ? ' · capacity ${a['capacity']}' : ''}'),
                          trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => _delete(a['id'])),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
