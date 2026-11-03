import 'package:latlong2/latlong.dart';

class SavedLocationModel {
  final String id;
  final String name;
  final String address;
  final LatLng coordinates;
  final String iconType; // 'home', 'work', 'college', 'transit', 'favorite'

  SavedLocationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.coordinates,
    this.iconType = 'favorite',
  });

  factory SavedLocationModel.fromJson(Map<String, dynamic> json) {
    return SavedLocationModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      coordinates: LatLng(
        (json['lat'] as num?)?.toDouble() ?? 17.3850,
        (json['lng'] as num?)?.toDouble() ?? 78.4867,
      ),
      iconType: json['icon_type'] ?? 'favorite',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'lat': coordinates.latitude,
      'lng': coordinates.longitude,
      'icon_type': iconType,
    };
  }
}
