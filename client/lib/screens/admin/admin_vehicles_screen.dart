import 'package:flutter/material.dart';
import '../../api_client.dart';

class AdminVehiclesScreen extends StatefulWidget {
  final int societyId;

  const AdminVehiclesScreen({super.key, required this.societyId});

  @override
  State<AdminVehiclesScreen> createState() => _AdminVehiclesScreenState();
}

class _AdminVehiclesScreenState extends State<AdminVehiclesScreen> {
  List<dynamic> _vehicles = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final vehicles = await ApiClient.societyVehicles(widget.societyId);
    setState(() {
      _vehicles = vehicles;
      _loading = false;
    });
  }

  List<dynamic> get _filtered {
    if (_query.isEmpty) return _vehicles;
    final q = _query.toLowerCase();
    return _vehicles.where((v) => v['plate_number'].toString().toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicles & parking')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search plate number'),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final v = _filtered[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Icon(v['vehicle_type'] == 'bike' ? Icons.two_wheeler : Icons.directions_car),
                            title: Text(v['plate_number']),
                            subtitle: Text('Flat #${v['flat_id']}${v['parking_slot'] != null ? ' · Slot ${v['parking_slot']}' : ''}'),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
