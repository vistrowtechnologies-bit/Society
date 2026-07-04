import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';

class AmenitiesScreen extends StatefulWidget {
  final int societyId;
  final int flatId;

  const AmenitiesScreen({super.key, required this.societyId, required this.flatId});

  @override
  State<AmenitiesScreen> createState() => _AmenitiesScreenState();
}

class _AmenitiesScreenState extends State<AmenitiesScreen> {
  List<dynamic> _amenities = [];
  List<dynamic> _myBookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final amenities = await ApiClient.amenities(widget.societyId);
    final bookings = await ApiClient.flatBookings(widget.flatId);
    setState(() {
      _amenities = amenities;
      _myBookings = bookings.where((b) => b['status'] == 'booked').toList();
      _loading = false;
    });
  }

  Future<void> _showBookDialog(Map<String, dynamic> amenity) async {
    DateTime date = DateTime.now().add(const Duration(days: 1));
    TimeOfDay start = const TimeOfDay(hour: 18, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 20, minute: 0);
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Book ${amenity['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(date.toIso8601String().split('T').first),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setDialogState(() => date = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start time'),
                subtitle: Text(start.format(ctx)),
                onTap: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: start);
                  if (picked != null) setDialogState(() => start = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('End time'),
                subtitle: Text(end.format(ctx)),
                onTap: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: end);
                  if (picked != null) setDialogState(() => end = picked);
                },
              ),
              if (error != null) Text(error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                String fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                try {
                  await ApiClient.bookAmenity(
                    amenityId: amenity['id'],
                    flatId: widget.flatId,
                    bookingDate: date.toIso8601String().split('T').first,
                    startTime: fmt(start),
                    endTime: fmt(end),
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  setDialogState(() => error = e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Book'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(int bookingId) async {
    await ApiClient.cancelBooking(bookingId);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Amenities')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Available amenities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (_amenities.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('No amenities set up yet', style: TextStyle(color: AppColors.textSecondary)))
                  else
                    ..._amenities.map((a) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(Icons.villa_outlined),
                            title: Text(a['name']),
                            subtitle: Text('${a['open_time']} - ${a['close_time']}${a['capacity'] != null ? ' · capacity ${a['capacity']}' : ''}'),
                            trailing: FilledButton(onPressed: () => _showBookDialog(a), child: const Text('Book')),
                          ),
                        )),
                  const SizedBox(height: 20),
                  const Text('My upcoming bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (_myBookings.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('No bookings yet', style: TextStyle(color: AppColors.textSecondary)))
                  else
                    ..._myBookings.map((b) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(Icons.event_available),
                            title: Text('${b['booking_date']}'),
                            subtitle: Text('${b['start_time']} - ${b['end_time']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => _cancel(b['id']),
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
