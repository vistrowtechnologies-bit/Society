import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';

class VehiclesScreen extends StatefulWidget {
  final int flatId;

  const VehiclesScreen({super.key, required this.flatId});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  List<dynamic> _vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final vehicles = await ApiClient.flatVehicles(widget.flatId);
    setState(() {
      _vehicles = vehicles;
      _loading = false;
    });
  }

  Future<void> _showAddDialog() async {
    final plateController = TextEditingController();
    final slotController = TextEditingController();
    String type = 'car';
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add vehicle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: plateController, decoration: const InputDecoration(labelText: 'Plate number')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'car', child: Text('Car')),
                  DropdownMenuItem(value: 'bike', child: Text('Bike')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setDialogState(() => type = v!),
              ),
              const SizedBox(height: 10),
              TextField(controller: slotController, decoration: const InputDecoration(labelText: 'Parking slot (optional)')),
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
                if (plateController.text.isEmpty) return;
                try {
                  await ApiClient.addVehicle(
                    flatId: widget.flatId,
                    plateNumber: plateController.text.trim().toUpperCase(),
                    vehicleType: type,
                    parkingSlot: slotController.text.trim().isEmpty ? null : slotController.text.trim(),
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
    await ApiClient.deleteVehicle(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My vehicles')),
      floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? const Center(child: Text('No vehicles added yet', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _vehicles.length,
                    itemBuilder: (context, i) {
                      final v = _vehicles[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(v['vehicle_type'] == 'bike' ? Icons.two_wheeler : Icons.directions_car),
                          title: Text(v['plate_number']),
                          subtitle: Text(v['parking_slot'] != null ? 'Slot ${v['parking_slot']}' : 'No slot assigned'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _delete(v['id']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
