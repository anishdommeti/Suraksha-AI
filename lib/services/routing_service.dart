import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
import '../models/route_model.dart';
import '../models/route_score_model.dart';

class RouteComparisonResult {
  final List<RouteModel> routes;
  final Map<String, RouteScoreModel> scores;
  final String recommendedRouteId;
  final String summary;
  final String dataMode;

  RouteComparisonResult({
    required this.routes,
    required this.scores,
    required this.recommendedRouteId,
    required this.summary,
    required this.dataMode,
  });
}

class RoutingService {
  // In-memory cache for calculated routes between coordinate pairs
  final Map<String, List<RouteModel>> _routeCache = {};

  static final List<RouteModel> demoRoutes = [
    RouteModel(
      routeId: 'route_arterial_saidabad',
      name: 'Route A: Main Arterial via Saidabad Main Rd',
      summary:
          'Commercial corridor with active traffic and commercial frontage.',
      distanceKm: 2.6,
      durationMinutes: 9,
      geometry: [
        LatLng(17.3596, 78.5085),
        LatLng(17.3610, 78.5090),
        LatLng(17.3645, 78.5088),
        LatLng(17.3685, 78.5075),
        LatLng(17.3712, 78.5028),
        LatLng(17.3735, 78.4965),
        LatLng(17.3753, 78.4908),
      ],
      isSimulated: true,
      source: 'Demonstration Fixture',
    ),
    RouteModel(
      routeId: 'route_colony_bypass',
      name: 'Route B: Interior Colony Shortcut via Singareni',
      summary:
          'Shorter distance but traverses isolated residential back-alleys.',
      distanceKm: 2.1,
      durationMinutes: 7,
      geometry: [
        LatLng(17.3596, 78.5085),
        LatLng(17.3615, 78.5060),
        LatLng(17.3642, 78.5041),
        LatLng(17.3661, 78.5015),
        LatLng(17.3685, 78.4988),
        LatLng(17.3698, 78.4962),
        LatLng(17.3753, 78.4908),
      ],
      isSimulated: true,
      source: 'Demonstration Fixture',
    ),
    RouteModel(
      routeId: 'route_transit_is_sadan',
      name: 'Route C: Link via IS Sadan Junction',
      summary: 'Longer route with divided carriageway and streetlights.',
      distanceKm: 3.1,
      durationMinutes: 12,
      geometry: [
        LatLng(17.3596, 78.5085),
        LatLng(17.3580, 78.5110),
        LatLng(17.3620, 78.5125),
        LatLng(17.3680, 78.5100),
        LatLng(17.3720, 78.5030),
        LatLng(17.3745, 78.4960),
        LatLng(17.3753, 78.4908),
      ],
      isSimulated: true,
      source: 'Demonstration Fixture',
    ),
  ];

  /// Direct road-route calculation using Open Source Routing Machine (OSRM).
  /// Decoupled from safety scoring. Decodes GeoJSON road geometry and supports alternatives.
  Future<List<RouteModel>> calculateRoadRoutes(
    LatLng origin,
    LatLng destination,
  ) async {
    // Validate coordinates
    if (origin.latitude < -90 ||
        origin.latitude > 90 ||
        origin.longitude < -180 ||
        origin.longitude > 180 ||
        destination.latitude < -90 ||
        destination.latitude > 90 ||
        destination.longitude < -180 ||
        destination.longitude > 180) {
      return [];
    }

    // Cache key
    final cacheKey =
        '${origin.latitude.toStringAsFixed(4)},${origin.longitude.toStringAsFixed(4)}->'
        '${destination.latitude.toStringAsFixed(4)},${destination.longitude.toStringAsFixed(4)}';

    if (_routeCache.containsKey(cacheKey)) {
      return _routeCache[cacheKey]!;
    }

    try {
      // OSRM coordinates format: {lon},{lat};{lon},{lat}
      final osrmUrl = Uri.parse(
        '${AppConfig.osrmBaseUrl}/route/v1/driving/'
        '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&alternatives=true',
      );

      final resp = await http
          .get(osrmUrl, headers: {'User-Agent': AppConfig.osmUserAgent})
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final routesList = data['routes'] as List<dynamic>? ?? [];

        if (routesList.isNotEmpty) {
          final List<RouteModel> calculatedRoutes = [];

          for (int i = 0; i < routesList.length; i++) {
            final r = routesList[i] as Map<String, dynamic>;
            final distanceMeters = (r['distance'] as num?)?.toDouble() ?? 0.0;
            final durationSeconds = (r['duration'] as num?)?.toDouble() ?? 0.0;
            final double distanceKm = double.parse(
              (distanceMeters / 1000.0).toStringAsFixed(2),
            );
            final int durationMinutes = (durationSeconds / 60.0).round();

            final geomData = r['geometry'] as Map<String, dynamic>? ?? {};
            final coordsRaw = geomData['coordinates'] as List<dynamic>? ?? [];

            // GeoJSON coordinates are [longitude, latitude]
            final List<LatLng> decodedCoords = [];
            for (var pt in coordsRaw) {
              if (pt is List && pt.length >= 2) {
                decodedCoords.add(
                  LatLng((pt[1] as num).toDouble(), (pt[0] as num).toDouble()),
                );
              }
            }

            final legs = r['legs'] as List<dynamic>? ?? [];
            String legSummary = '';
            if (legs.isNotEmpty) {
              legSummary = (legs[0] as Map<String, dynamic>)['summary'] ?? '';
            }
            if (legSummary.isEmpty) {
              legSummary = i == 0
                  ? 'Primary Road Route'
                  : 'Alternative Road Route';
            }

            final letter = String.fromCharCode(65 + i);
            calculatedRoutes.add(
              RouteModel(
                routeId: 'osrm_route_$i',
                name: 'Route $letter: via $legSummary',
                summary:
                    'Road-routed via OSRM ($distanceKm km, $durationMinutes mins).',
                distanceKm: distanceKm,
                durationMinutes: durationMinutes,
                geometry: decodedCoords,
                isSimulated: false,
                source: 'OSRM Open Road Network',
              ),
            );
          }

          if (calculatedRoutes.isNotEmpty) {
            _routeCache[cacheKey] = calculatedRoutes;
            return calculatedRoutes;
          }
        }
      }
    } catch (_) {
      // Graceful offline fallback
    }

    return demoRoutes;
  }

  Future<List<RouteModel>> getRoutes(String origin, String destination) async {
    try {
      final url = Uri.parse('${AppConfig.backendBaseUrl}/api/routes');
      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'origin': origin, 'destination': destination}),
          )
          .timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        final List list = json.decode(resp.body);
        return list.map((e) => RouteModel.fromJson(e)).toList();
      }
    } catch (_) {
      // Offline fallback
    }
    return demoRoutes;
  }

  Future<RouteComparisonResult> compareRoutes(
    String origin,
    String destination,
  ) async {
    try {
      final url = Uri.parse('${AppConfig.backendBaseUrl}/api/routes/compare');
      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'origin': origin, 'destination': destination}),
          )
          .timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final routesList = (data['routes'] as List)
            .map((e) => RouteModel.fromJson(e))
            .toList();
        final Map<String, RouteScoreModel> scoresMap = {};
        (data['scores'] as Map<String, dynamic>).forEach((k, v) {
          scoresMap[k] = RouteScoreModel.fromJson(v);
        });

        return RouteComparisonResult(
          routes: routesList,
          scores: scoresMap,
          recommendedRouteId:
              data['recommended_route_id'] ?? routesList.first.routeId,
          summary: data['comparison_summary'] ?? '',
          dataMode: data['data_mode'] ?? 'SIMULATED_DEMO_DATA',
        );
      }
    } catch (_) {
      // Offline fallback
    }

    final Map<String, RouteScoreModel> scores = {
      'route_arterial_saidabad': RouteScoreModel(
        routeId: 'route_arterial_saidabad',
        score: 18.4,
        scoreStatus: 'calculated',
        verifiedIncidentCount: 1,
        pendingReportCount: 1,
        distanceKm: 2.6,
        durationMinutes: 9,
        exposureDensity: 0.38,
        evidenceSummary: '1 verified incident along commercial corridor.',
        limitations: 'Demonstration heuristic. Does not guarantee safety.',
        dataMode: 'SIMULATED_DEMO_DATA',
        sourcesConsulted: ['Hyderabad Traffic Police', 'OpenCity Data'],
      ),
      'route_colony_bypass': RouteScoreModel(
        routeId: 'route_colony_bypass',
        score: 52.0,
        scoreStatus: 'calculated',
        verifiedIncidentCount: 4,
        pendingReportCount: 0,
        distanceKm: 2.1,
        durationMinutes: 7,
        exposureDensity: 1.90,
        evidenceSummary: '4 verified incidents (lighting defects, deserted stretch, harassment record).',
        limitations: 'High incident density in residential corridor.',
        dataMode: 'SIMULATED_DEMO_DATA',
        sourcesConsulted: ['Telangana SHE Teams', 'GHMC Lighting Audit'],
      ),
      'route_transit_is_sadan': RouteScoreModel(
        routeId: 'route_transit_is_sadan',
        score: 34.0,
        scoreStatus: 'calculated',
        verifiedIncidentCount: 2,
        pendingReportCount: 1,
        distanceKm: 3.1,
        durationMinutes: 12,
        exposureDensity: 0.97,
        evidenceSummary: '2 verified incidents along transit corridor.',
        limitations: 'Longer route exposure.',
        dataMode: 'SIMULATED_DEMO_DATA',
        sourcesConsulted: ['Hyderabad Traffic Police'],
      ),
    };

    return RouteComparisonResult(
      routes: demoRoutes,
      scores: scores,
      recommendedRouteId: 'route_arterial_saidabad',
      summary: 'Route A has fewer recorded incidents (1 vs 4) and a lower heuristic score (18.4/100).',
      dataMode: 'SIMULATED_DEMO_DATA',
    );
  }

  void clearCache() {
    _routeCache.clear();
  }
}
