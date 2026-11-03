import 'package:latlong2/latlong.dart';

class PhotonFeature {
  final String name;
  final String? street;
  final String? city;
  final String? state;
  final String? country;
  final String? postcode;
  final String? osmType;
  final int? osmId;
  final LatLng coordinates;

  PhotonFeature({
    required this.name,
    this.street,
    this.city,
    this.state,
    this.country,
    this.postcode,
    this.osmType,
    this.osmId,
    required this.coordinates,
  });

  String get displayName {
    final parts = <String>[];
    if (name.isNotEmpty) parts.add(name);
    if (street != null && street!.isNotEmpty && street != name) {
      parts.add(street!);
    }
    if (city != null && city!.isNotEmpty && city != name) parts.add(city!);
    if (state != null && state!.isNotEmpty && state != city) parts.add(state!);
    return parts.isEmpty ? 'Unknown Location' : parts.join(', ');
  }

  String get subtitle {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (postcode != null && postcode!.isNotEmpty) parts.add(postcode!);
    return parts.join(', ');
  }

  factory PhotonFeature.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>? ?? {};
    final geometry = json['geometry'] as Map<String, dynamic>? ?? {};
    final coords =
        geometry['coordinates'] as List<dynamic>? ?? [78.4867, 17.3850];

    // GeoJSON coordinates are [longitude, latitude]
    final double lng = (coords[0] as num).toDouble();
    final double lat = (coords[1] as num).toDouble();

    return PhotonFeature(
      name: properties['name'] ?? properties['street'] ?? 'Point of Interest',
      street: properties['street'],
      city: properties['city'] ?? properties['district'],
      state: properties['state'],
      country: properties['country'],
      postcode: properties['postcode'],
      osmType: properties['osm_type'],
      osmId: (properties['osm_id'] as num?)?.toInt(),
      coordinates: LatLng(lat, lng),
    );
  }
}
