import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/saved_location_model.dart';

class SavedLocationsService extends ChangeNotifier {
  final List<SavedLocationModel> _locations = [
    SavedLocationModel(
      id: 'loc_college',
      name: 'Matrusri Engineering College',
      address: 'Saidabad Main Rd, Saidabad, Hyderabad',
      coordinates: LatLng(17.3596, 78.5085),
      iconType: 'college',
    ),
    SavedLocationModel(
      id: 'loc_metro',
      name: 'Saidabad Metro Station',
      address: 'Chanchalguda - Saidabad Corridor, Hyderabad',
      coordinates: LatLng(17.3753, 78.4908),
      iconType: 'transit',
    ),
    SavedLocationModel(
      id: 'loc_home',
      name: 'Home (Malakpet)',
      address: 'Near Old Malakpet PS, Hyderabad',
      coordinates: LatLng(17.3760, 78.4900),
      iconType: 'home',
    ),
    SavedLocationModel(
      id: 'loc_hospital',
      name: 'Osmania General Hospital',
      address: 'Afzal Gunj, Hyderabad',
      coordinates: LatLng(17.3732, 78.4776),
      iconType: 'favorite',
    ),
  ];

  List<SavedLocationModel> get locations => List.unmodifiable(_locations);

  void addLocation(SavedLocationModel loc) {
    _locations.add(loc);
    notifyListeners();
  }

  void removeLocation(String id) {
    _locations.removeWhere((l) => l.id == id);
    notifyListeners();
  }
}
