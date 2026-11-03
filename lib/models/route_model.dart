import 'package:latlong2/latlong.dart';

class RouteModel {
  final String routeId;
  final String name;
  final String summary;
  final double distanceKm;
  final int durationMinutes;
  final List<LatLng> geometry;
  final bool isSimulated;
  final String source;

  RouteModel({
    required this.routeId,
    required this.name,
    required this.summary,
    required this.distanceKm,
    required this.durationMinutes,
    required this.geometry,
    this.isSimulated = false,
    this.source = 'OSRM',
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    var rawGeom = json['geometry'] as List<dynamic>? ?? [];
    List<LatLng> coords = [];
    for (var pt in rawGeom) {
      if (pt is List && pt.length >= 2) {
        coords.add(
          LatLng((pt[0] as num).toDouble(), (pt[1] as num).toDouble()),
        );
      }
    }

    return RouteModel(
      routeId: json['route_id'] ?? '',
      name: json['name'] ?? 'Route',
      summary: json['summary'] ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      geometry: coords,
      isSimulated: json['is_simulated'] ?? false,
      source: json['source'] ?? 'OSRM',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_id': routeId,
      'name': name,
      'summary': summary,
      'distance_km': distanceKm,
      'duration_minutes': durationMinutes,
      'geometry': geometry.map((pt) => [pt.latitude, pt.longitude]).toList(),
      'is_simulated': isSimulated,
      'source': source,
    };
  }
}
