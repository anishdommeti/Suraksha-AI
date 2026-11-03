import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../models/saved_location_model.dart';
import '../services/saved_locations_service.dart';
import '../services/location_service.dart';

class SavedLocationsScreen extends StatelessWidget {
  final Function(SavedLocationModel)? onSelectAsDestination;

  const SavedLocationsScreen({super.key, this.onSelectAsDestination});

  IconData _getIconData(String iconType) {
    switch (iconType) {
      case 'home':
        return Icons.home_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'college':
        return Icons.school_rounded;
      case 'transit':
        return Icons.train_rounded;
      case 'favorite':
      default:
        return Icons.star_rounded;
    }
  }

  Color _getIconColor(String iconType) {
    switch (iconType) {
      case 'home':
        return const Color(0xFF0288D1);
      case 'work':
        return const Color(0xFF5E35B1);
      case 'college':
        return const Color(0xFF00897B);
      case 'transit':
        return const Color(0xFFE65100);
      case 'favorite':
      default:
        return const Color(0xFFFFB300);
    }
  }

  void _showAddLocationDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final latCtrl = TextEditingController(text: '17.3850');
    final lngCtrl = TextEditingController(text: '78.4867');
    String selectedIcon = 'favorite';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text(
            'Add Saved Location',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location Name (e.g. Gym, Library)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address or Area',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: lngCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedIcon,
                  decoration: const InputDecoration(labelText: 'Category Icon'),
                  items: const [
                    DropdownMenuItem(value: 'home', child: Text('Home')),
                    DropdownMenuItem(value: 'work', child: Text('Work')),
                    DropdownMenuItem(
                      value: 'college',
                      child: Text('College/School'),
                    ),
                    DropdownMenuItem(
                      value: 'transit',
                      child: Text('Metro/Transit'),
                    ),
                    DropdownMenuItem(
                      value: 'favorite',
                      child: Text('Favorite'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedIcon = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final lat = double.tryParse(latCtrl.text);
                final lng = double.tryParse(lngCtrl.text);

                if (name.isNotEmpty && lat != null && lng != null) {
                  final newLoc = SavedLocationModel(
                    id: 'saved_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    address: addressCtrl.text.trim().isEmpty
                        ? 'Hyderabad, Telangana'
                        : addressCtrl.text.trim(),
                    coordinates: LatLng(lat, lng),
                    iconType: selectedIcon,
                  );
                  Provider.of<SavedLocationsService>(
                    context,
                    listen: false,
                  ).addLocation(newLoc);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedService = Provider.of<SavedLocationsService>(context);
    final locs = savedService.locations;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        title: const Text(
          'Saved Locations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_location_alt_outlined,
              color: Colors.white,
            ),
            tooltip: 'Add Location',
            onPressed: () => _showAddLocationDialog(context),
          ),
        ],
      ),
      body: locs.isEmpty
          ? const Center(
              child: Text(
                'No saved locations yet. Tap + to add one.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: locs.length,
              itemBuilder: (context, idx) {
                final item = locs[idx];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getIconColor(item.iconType)
                          .withValues(alpha: 0.15),
                      child: Icon(
                        _getIconData(item.iconType),
                        color: _getIconColor(item.iconType),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${item.address}\n(${item.coordinates.latitude.toStringAsFixed(4)}, ${item.coordinates.longitude.toStringAsFixed(4)})',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.directions_outlined,
                            color: Color(0xFF00796B),
                          ),
                          tooltip: 'Route to this place',
                          onPressed: () {
                            final locService = Provider.of<LocationService>(
                              context,
                              listen: false,
                            );
                            locService.setDestination(
                              item.name,
                              item.coordinates,
                            );
                            if (onSelectAsDestination != null) {
                              onSelectAsDestination!(item);
                            }
                            Navigator.pop(context);
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          tooltip: 'Delete',
                          onPressed: () => savedService.removeLocation(item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
