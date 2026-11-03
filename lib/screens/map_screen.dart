import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../models/route_model.dart';
import '../models/route_score_model.dart';
import '../models/incident_model.dart';
import '../models/facility_model.dart';
import '../models/photon_feature.dart';
import '../services/routing_service.dart';
import '../services/incident_service.dart';
import '../services/location_service.dart';
import '../services/photon_service.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';
import '../services/navigation_launcher_service.dart';
import '../services/emergency_service.dart';
import 'assistant_screen.dart';
import 'score_explanation_screen.dart';
import 'report_incident_screen.dart';
import 'my_reports_screen.dart';
import 'saved_locations_screen.dart';
import 'settings_screen.dart';

class MapScreen extends StatefulWidget {
  final String? initialSelectedRouteId;

  const MapScreen({super.key, this.initialSelectedRouteId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  gmaps.GoogleMapController? _googleMapController;
  final RoutingService _routingService = RoutingService();
  final PhotonService _photonService = PhotonService();

  // Search State
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  Timer? _debounceTimer;
  List<PhotonFeature> _searchSuggestions = [];
  bool _isSearching = false;
  int _searchRequestId = 0;
  bool _isSearchingOrigin = false; // false = searching destination, true = searching origin

  // Routes & Scores
  List<RouteModel> _routes = [];
  Map<String, RouteScoreModel> _scores = {};
  String _selectedRouteId = '';
  String _recommendedRouteId = '';
  bool _isLoading = false;
  bool _isRouting = false;

  // Map Style & Theming
  String _darkMapStyleJson = '';

  // Filters & Legend
  String _selectedCategoryFilter = 'ALL';
  bool _showFacilities = true;
  bool _isRouteSheetExpanded = true;
  bool _isLegendExpanded = false;

  // Zoom-Responsive Marker Scaling
  // Tier 0: Wide zoom (< 12.0) -> Compact dot (18px)
  // Tier 1: Medium zoom (12.0 - 14.5) -> Standard pin (28px)
  // Tier 2: Close zoom (>= 14.5) -> High-detail pin (40px)
  int _currentZoomTier = 1;
  static final Map<String, gmaps.BitmapDescriptor> _markerBitmapCache = {};

  // Marker Memoization
  Set<gmaps.Marker> _cachedMarkers = {};
  Set<gmaps.Polyline> _cachedPolylines = {};
  int _lastMarkerHash = 0;
  int _lastPolylineHash = 0;

  static const double kRouteProximityThresholdMeters = 500.0;
  static const double kFacilityProximityThresholdMeters = 1000.0;

  final List<String> _categoryFilterOptions = [
    'ALL',
    'ROAD_ACCIDENT',
    'WOMEN_SAFETY',
    'HARASSMENT',
    'POOR_STREET_LIGHTING',
    'TRAFFIC_HAZARD',
    'ROAD_OBSTRUCTION',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedRouteId != null) {
      _selectedRouteId = widget.initialSelectedRouteId!;
    }
    _searchFocusNode.addListener(_handleSearchFocusChange);
    _loadMapStyle();
    _loadInitialData();
  }

  void _handleSearchFocusChange() {
    if (mounted && _searchFocusNode.hasFocus != _isSearchFocused) {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    }
  }

  void _exitSearchFocus() {
    _searchFocusNode.unfocus();
    setState(() {
      _isSearchFocused = false;
      _searchSuggestions = [];
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchFocusNode.removeListener(_handleSearchFocusChange);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMapStyle() async {
    try {
      _darkMapStyleJson = await rootBundle.loadString(
        'assets/map_styles/dark_map_style.json',
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[SURAKSHA AI] Could not load dark map style asset: $e');
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final incidentService = Provider.of<IncidentService>(
      context,
      listen: false,
    );

    await incidentService.fetchIncidents(
      category: _selectedCategoryFilter == 'ALL'
          ? null
          : _selectedCategoryFilter,
    );
    await incidentService.fetchFacilities();
    await incidentService.fetchDatasetSummary();

    // Pre-cache dynamic zoom marker bitmaps in background
    _initMarkerBitmaps();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Pre-generates and caches custom circular marker icons across zoom tiers
  Future<void> _initMarkerBitmaps() async {
    final categories = {
      'ROAD_ACCIDENT': const Color(0xFFC62828),
      'WOMEN_SAFETY': const Color(0xFF8E24AA),
      'HARASSMENT': const Color(0xFF6A1B9A),
      'POOR_STREET_LIGHTING': const Color(0xFFF9A825),
      'TRAFFIC_HAZARD': const Color(0xFFE65100),
      'ROAD_OBSTRUCTION': const Color(0xFFC2185B),
      'PENDING': const Color(0xFF1976D2),
      'FACILITY': const Color(0xFF00897B),
    };

    for (final entry in categories.entries) {
      for (int tier = 0; tier < 3; tier++) {
        final key = '${entry.key}_$tier';
        if (!_markerBitmapCache.containsKey(key)) {
          final double size = tier == 0 ? 18.0 : (tier == 1 ? 28.0 : 40.0);
          try {
            final desc = await _generateCircleMarkerBitmap(
              color: entry.value,
              size: size,
              tier: tier,
            );
            _markerBitmapCache[key] = desc;
          } catch (e) {
            debugPrint('[SURAKSHA AI] Error generating bitmap marker for $key: $e');
          }
        }
      }
    }
    if (mounted) setState(() {});
  }

  /// Generates a crisp canvas bitmap descriptor for dynamic map zoom
  Future<gmaps.BitmapDescriptor> _generateCircleMarkerBitmap({
    required Color color,
    required double size,
    required int tier,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final radius = (size / 2) - (tier == 0 ? 1.5 : 2.5);

    // 1. Soft Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(Offset(center.dx, center.dy + 1.5), radius, shadowPaint);

    // 2. Colored Fill
    final bodyPaint = Paint()..color = color;
    canvas.drawCircle(center, radius, bodyPaint);

    // 3. Crisp White Outline Ring
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = tier == 0 ? 1.5 : (tier == 1 ? 2.5 : 3.5);
    canvas.drawCircle(center, radius, borderPaint);

    // 4. Inner White Core for Medium & Close Tiers
    if (tier > 0) {
      final innerPaint = Paint()..color = Colors.white;
      final innerRadius = tier == 1 ? 3.5 : 5.5;
      canvas.drawCircle(center, innerRadius, innerPaint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return gmaps.BitmapDescriptor.bytes(bytes, width: size, height: size);
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final currentReqId = ++_searchRequestId;

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await _photonService.search(trimmed, limit: 6);
        if (mounted && _searchRequestId == currentReqId) {
          setState(() {
            _searchSuggestions = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted && _searchRequestId == currentReqId) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  void _selectSearchSuggestion(PhotonFeature feature) {
    final loc = Provider.of<LocationService>(context, listen: false);
    _searchFocusNode.unfocus();

    if (_isSearchingOrigin) {
      loc.setOrigin(feature.displayName, feature.coordinates);
    } else {
      loc.setDestination(feature.displayName, feature.coordinates);
    }

    _googleMapController?.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: gmaps.LatLng(
            feature.coordinates.latitude,
            feature.coordinates.longitude,
          ),
          zoom: 14.5,
        ),
      ),
    );

    setState(() {
      _isSearchFocused = false;
      _searchController.clear();
      _searchSuggestions = [];
    });
  }

  Future<void> _planRoadRoute(ll.LatLng origin, ll.LatLng destination) async {
    setState(() => _isRouting = true);
    final locService = Provider.of<LocalizationService>(context, listen: false);
    final incidentService = Provider.of<IncidentService>(context, listen: false);

    try {
      // 1. Fetch real road geometry via OSRM
      List<RouteModel> roadRoutes = await _routingService.calculateRoadRoutes(
        origin,
        destination,
      );

      // Fallback straight-line route if offline or OSRM unavailable
      if (roadRoutes.isEmpty) {
        final distKm = double.parse(
          (const ll.Distance().as(ll.LengthUnit.Meter, origin, destination) / 1000.0).toStringAsFixed(1),
        );
        roadRoutes = [
          RouteModel(
            routeId: 'route_primary_direct',
            name: 'Primary Arterial Corridor',
            summary: 'Direct route between endpoints',
            distanceKm: max(distKm, 0.5),
            durationMinutes: max(5, (distKm * 2.5).round()),
            geometry: [origin, destination],
            isSimulated: true,
            source: 'Demonstration Fixture',
          ),
        ];
      }

      // 2. Mathematical corridor exposure scoring (<15ms in-memory calculation)
      final allIncidents = incidentService.incidents;
      final Map<String, RouteScoreModel> scoresMap = {};

      String bestRouteId = roadRoutes.first.routeId;
      double lowestScore = 999.0;

      for (final route in roadRoutes) {
        final score = _calculateCorridorSafetyScore(route, allIncidents);
        scoresMap[route.routeId] = score;

        if (score.score < lowestScore) {
          lowestScore = score.score;
          bestRouteId = route.routeId;
        }
      }

      if (mounted) {
        setState(() {
          _routes = roadRoutes;
          _scores = scoresMap;
          _selectedRouteId = bestRouteId;
          _recommendedRouteId = bestRouteId;
          _isRouting = false;
        });

        // Fit map camera bounds to the planned road geometry
        final selectedRoute = roadRoutes.firstWhere(
          (r) => r.routeId == bestRouteId,
          orElse: () => roadRoutes.first,
        );
        _fitRouteBounds(selectedRoute.geometry);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRouting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${locService.t("error")}: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  /// Strict Mathematical corridor exposure analysis based on verified incidents
  RouteScoreModel _calculateCorridorSafetyScore(RouteModel route, List<IncidentModel> allIncidents) {
    const corridorMeters = 200.0;
    const distanceCalculator = ll.Distance();
    int verifiedCount = 0;
    int pendingCount = 0;
    double weightedSum = 0.0;
    final hazardCounts = <String, int>{};

    for (final inc in allIncidents) {
      if (!inc.hasCoordinates) continue;
      final incPoint = ll.LatLng(inc.latitude!, inc.longitude!);
      bool isNear = false;

      final step = max(1, (route.geometry.length / 40).ceil());
      for (int i = 0; i < route.geometry.length; i += step) {
        if (distanceCalculator.as(ll.LengthUnit.Meter, incPoint, route.geometry[i]) <= corridorMeters) {
          isNear = true;
          break;
        }
      }

      if (isNear) {
        if (inc.isVerified) {
          verifiedCount++;
          double weight = 1.0;
          if (inc.category == 'HARASSMENT' || inc.category == 'ASSAULT' || inc.category == 'WOMEN_SAFETY') {
            weight = 3.0;
          } else if (inc.category == 'POOR_STREET_LIGHTING' || inc.category == 'UNSAFE_OR_ISOLATED_AREA') {
            weight = 1.5;
          } else if (inc.category == 'ROAD_ACCIDENT') {
            weight = 2.0;
          }
          weightedSum += weight;
          hazardCounts[inc.formattedCategory] = (hazardCounts[inc.formattedCategory] ?? 0) + 1;
        } else if (inc.isPending) {
          pendingCount++;
        }
      }
    }

    final effDistance = max(route.distanceKm, 0.5);
    final exposureDensity = double.parse((weightedSum / effDistance).toStringAsFixed(2));
    final score = min(100.0, double.parse((10.0 + (exposureDensity * 22.0)).toStringAsFixed(1)));

    final topHazards = (hazardCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)))
      .map((e) => e.key)
      .take(3)
      .toList();

    return RouteScoreModel(
      routeId: route.routeId,
      score: score,
      scoreStatus: 'calculated',
      verifiedIncidentCount: verifiedCount,
      pendingReportCount: pendingCount,
      distanceKm: route.distanceKm,
      durationMinutes: route.durationMinutes,
      exposureDensity: exposureDensity,
      evidenceSummary: verifiedCount > 0
          ? '$verifiedCount verified hazards (${topHazards.join(", ")}) along ${route.distanceKm} km.'
          : '0 recorded hazards along ${route.distanceKm} km corridor.',
      limitations: 'Calculated using 200m spatial corridor. Low score reflects fewer records, not absolute safety.',
      dataMode: 'REAL_INCIDENT_CORRIDOR_AUDIT',
      sourcesConsulted: ['Hyderabad Traffic Police', 'Telangana SHE Teams', 'GHMC Civic Audits'],
      topHazards: topHazards,
    );
  }

  /// Calculates whether a geographic point is within a corridor of route geometry
  bool _isIncidentNearRoute(
    ll.LatLng point,
    List<ll.LatLng> routeGeometry, {
    double proximityMeters = kRouteProximityThresholdMeters,
  }) {
    if (routeGeometry.isEmpty) return false;

    // 1. Fast Bounding Box test for O(1) bulk rejection
    double minLat = routeGeometry.first.latitude;
    double maxLat = routeGeometry.first.latitude;
    double minLng = routeGeometry.first.longitude;
    double maxLng = routeGeometry.first.longitude;

    for (int i = 1; i < routeGeometry.length; i++) {
      final p = routeGeometry[i];
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    // 500m in degrees latitude/longitude at Hyderabad (~17.4N) is ~0.005 degrees
    const bufferDegrees = 0.006;
    if (point.latitude < minLat - bufferDegrees ||
        point.latitude > maxLat + bufferDegrees ||
        point.longitude < minLng - bufferDegrees ||
        point.longitude > maxLng + bufferDegrees) {
      return false;
    }

    // 2. Sampled distance calculation along route polyline
    const distanceCalc = ll.Distance();
    final step = max(1, (routeGeometry.length / 60).ceil());
    for (int i = 0; i < routeGeometry.length; i += step) {
      if (distanceCalc.as(ll.LengthUnit.Meter, point, routeGeometry[i]) <= proximityMeters) {
        return true;
      }
    }

    return false;
  }

  void _fitRouteBounds(List<ll.LatLng> points) {
    if (points.isEmpty || _googleMapController == null) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _googleMapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngBounds(
        gmaps.LatLngBounds(
          southwest: gmaps.LatLng(minLat, minLng),
          northeast: gmaps.LatLng(maxLat, maxLng),
        ),
        60.0,
      ),
    );
  }

  void _clearRoute() {
    setState(() {
      _routes = [];
      _scores = {};
      _selectedRouteId = '';
      _recommendedRouteId = '';
    });
  }

  void _onMapTapped(ll.LatLng point) {
    final loc = Provider.of<LocationService>(context, listen: false);
    final locService = Provider.of<LocalizationService>(context, listen: false);

    if (_isSearchingOrigin) {
      loc.setOrigin(
        'Selected: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
        point,
      );
    } else {
      loc.setDestination(
        'Selected: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
        point,
      );
    }

    // Simple, unambiguous confirmation feedback without duplicate 'Plan Route' actions
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSearchingOrigin
              ? '${locService.t("origin_label")}: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}'
              : '${locService.t("destination_label")}: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
        ),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  Future<void> _centerOnCurrentLocation() async {
    final loc = Provider.of<LocationService>(context, listen: false);
    final locService = Provider.of<LocalizationService>(context, listen: false);

    final success = await loc.requestCurrentLocation(updateOrigin: false);
    if (success && loc.currentGpsCoords != null) {
      _googleMapController?.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(
            target: gmaps.LatLng(
              loc.currentGpsCoords!.latitude,
              loc.currentGpsCoords!.longitude,
            ),
            zoom: 15.0,
          ),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.statusMessage.isNotEmpty ? loc.statusMessage : locService.t('location_unavailable')),
          ),
        );
      }
    }
  }

  void _zoomIn() {
    _googleMapController?.animateCamera(gmaps.CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _googleMapController?.animateCamera(gmaps.CameraUpdate.zoomOut());
  }

  void _onFilterChanged(String cat) {
    setState(() {
      _selectedCategoryFilter = cat;
    });
    final incidentService = Provider.of<IncidentService>(
      context,
      listen: false,
    );
    incidentService.fetchIncidents(category: cat == 'ALL' ? null : cat);
  }

  void _showIncidentDetails(IncidentModel inc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF141C33) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: inc.isVerified
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: inc.isVerified
                            ? const Color(0xFF81C784)
                            : const Color(0xFF90CAF9),
                      ),
                    ),
                    child: Text(
                      inc.isVerified ? 'VERIFIED RECORD' : 'PENDING COMMUNITY REPORT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: inc.isVerified
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Severity: ${inc.severity}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: inc.severity == 'CRITICAL' || inc.severity == 'HIGH'
                          ? const Color(0xFFC62828)
                          : const Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                inc.formattedCategory,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                inc.description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF455A64),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              Text(
                'Source: ${inc.sourceName}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              if (inc.hasCoordinates)
                Text(
                  'Location: ${inc.latitude!.toStringAsFixed(4)}, ${inc.longitude!.toStringAsFixed(4)} (${inc.locationPrecision})',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFacilityDetails(PublicFacilityModel f) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF141C33) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF80CBC4)),
                    ),
                    child: Text(
                      f.facilityType.replaceAll('_', ' '),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00796B),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '24x7 Official Support',
                    style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                f.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                f.description ?? f.jurisdiction,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? Colors.grey.shade300
                      : const Color(0xFF455A64),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (f.phoneNumber != null && f.phoneNumber!.isNotEmpty)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.call, size: 14),
                      label: Text(f.phoneNumber!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00796B),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        EmergencyService.promptAndLaunchHelpline(
                          context,
                          number: f.phoneNumber!,
                          title: f.name,
                          description: 'Public Safety Dispatch Call',
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWhyThisScoreDialog(RouteModel route, RouteScoreModel? score) {
    final locService = Provider.of<LocalizationService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF141C33) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFF00796B), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  locService.t('score_explanation_title'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Route: ${route.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Color(0xFF2E7D32), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Score: ${score?.score.toStringAsFixed(1) ?? "N/A"}/100 (${score?.scoreCategory ?? "Heuristic"})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'How this score was calculated:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  score?.evidenceSummary ??
                      'Computed based on verified accident blackspots and safety incidents within a 200m spatial corridor along the OSRM road geometry.',
                  style: const TextStyle(fontSize: 11, height: 1.35),
                ),
                const SizedBox(height: 10),
                const Divider(),
                const Text(
                  'Methodology Transparency:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Uses strictly documented police blackspots and verified audit records.\n'
                  '• Incident density per kilometer is evaluated.\n'
                  '• Low score reflects fewer recorded hazards, not an absolute guarantee of safety.',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey, height: 1.35),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(locService.t('close')),
            ),
          ],
        );
      },
    );
  }

  void _showStackInfoDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF141C33) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.layers_outlined, color: Color(0xFF00796B), size: 22),
              SizedBox(width: 8),
              Text('Mapping Architecture', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Map Engine: Google Maps SDK for Android', style: TextStyle(fontSize: 12)),
              SizedBox(height: 4),
              Text('• Routing: Open Source Routing Machine (OSRM)', style: TextStyle(fontSize: 12)),
              SizedBox(height: 4),
              Text('• Geocoding: Photon Search (OSM data by Komoot)', style: TextStyle(fontSize: 12)),
              SizedBox(height: 4),
              Text('• Data Sources: Hyderabad Traffic Police, SHE Teams, GHMC', style: TextStyle(fontSize: 12)),
              SizedBox(height: 4),
              Text('• Attribution: © OpenStreetMap contributors', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Memoized marker generator with Route-Aware Filtering & Dynamic Zoom Scaling
  Set<gmaps.Marker> _buildMemoizedMarkers(
    LocationService loc,
    List<IncidentModel> incidents,
    List<PublicFacilityModel> facilities,
  ) {
    final bool isRouteActive = _routes.isNotEmpty;
    RouteModel? activeRoute;
    if (isRouteActive) {
      try {
        activeRoute = _routes.firstWhere((r) => r.routeId == _selectedRouteId);
      } catch (_) {
        activeRoute = _routes.first;
      }
    }

    int currentHash = Object.hash(
      loc.originCoords.latitude,
      loc.originCoords.longitude,
      loc.destinationCoords.latitude,
      loc.destinationCoords.longitude,
      incidents.length,
      facilities.length,
      _selectedCategoryFilter,
      _showFacilities,
      _selectedRouteId,
      _routes.length,
      _currentZoomTier,
    );

    if (currentHash == _lastMarkerHash && _cachedMarkers.isNotEmpty) {
      return _cachedMarkers;
    }

    _lastMarkerHash = currentHash;
    final Set<gmaps.Marker> markers = {};

    // 1. Origin Marker (Green)
    markers.add(
      gmaps.Marker(
        markerId: const gmaps.MarkerId('marker_origin'),
        position: gmaps.LatLng(loc.originCoords.latitude, loc.originCoords.longitude),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen),
        infoWindow: gmaps.InfoWindow(
          title: 'Origin (Starting Point)',
          snippet: loc.origin,
        ),
      ),
    );

    // 2. Destination Marker (Red)
    markers.add(
      gmaps.Marker(
        markerId: const gmaps.MarkerId('marker_destination'),
        position: gmaps.LatLng(loc.destinationCoords.latitude, loc.destinationCoords.longitude),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
        infoWindow: gmaps.InfoWindow(
          title: 'Destination',
          snippet: loc.destination,
        ),
      ),
    );

    // 3. Incident Markers (Route-Aware & Scaled by Zoom Tier)
    for (final inc in incidents) {
      if (!inc.hasCoordinates) continue;

      if (_selectedCategoryFilter != 'ALL' && inc.category != _selectedCategoryFilter) {
        continue;
      }

      final incPoint = ll.LatLng(inc.latitude!, inc.longitude!);

      // Route-aware filtering: When route is active, ONLY show incidents near the active route corridor (500m)
      if (isRouteActive && activeRoute != null && activeRoute.geometry.isNotEmpty) {
        if (!_isIncidentNearRoute(incPoint, activeRoute.geometry, proximityMeters: kRouteProximityThresholdMeters)) {
          continue;
        }
      }

      double hue = gmaps.BitmapDescriptor.hueRed;
      String iconKey = 'ROAD_ACCIDENT';

      if (inc.category == 'WOMEN_SAFETY') {
        hue = gmaps.BitmapDescriptor.hueViolet;
        iconKey = 'WOMEN_SAFETY';
      } else if (inc.category == 'HARASSMENT') {
        hue = gmaps.BitmapDescriptor.hueViolet;
        iconKey = 'HARASSMENT';
      } else if (inc.category == 'POOR_STREET_LIGHTING') {
        hue = gmaps.BitmapDescriptor.hueYellow;
        iconKey = 'POOR_STREET_LIGHTING';
      } else if (inc.category == 'TRAFFIC_HAZARD') {
        hue = gmaps.BitmapDescriptor.hueOrange;
        iconKey = 'TRAFFIC_HAZARD';
      } else if (inc.category == 'ROAD_OBSTRUCTION') {
        hue = gmaps.BitmapDescriptor.hueMagenta;
        iconKey = 'ROAD_OBSTRUCTION';
      } else if (!inc.isVerified) {
        hue = gmaps.BitmapDescriptor.hueBlue;
        iconKey = 'PENDING';
      }

      // Retrieve dynamic zoom-scaled bitmap descriptor (with hue fallback)
      final customIcon = _markerBitmapCache['${iconKey}_$_currentZoomTier'] ??
          gmaps.BitmapDescriptor.defaultMarkerWithHue(hue);

      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('inc_${inc.id}'),
          position: gmaps.LatLng(inc.latitude!, inc.longitude!),
          icon: customIcon,
          infoWindow: gmaps.InfoWindow(
            title: '${inc.isVerified ? "[Verified]" : "[Pending]"} ${inc.formattedCategory}',
            snippet: inc.description,
            onTap: () => _showIncidentDetails(inc),
          ),
          onTap: () => _showIncidentDetails(inc),
        ),
      );
    }

    // 4. Public Facilities (Cyan / Teal - Route-Aware when route planned)
    if (_showFacilities) {
      final facIcon = _markerBitmapCache['FACILITY_$_currentZoomTier'] ??
          gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueCyan);

      for (final f in facilities) {
        final facPoint = ll.LatLng(f.latitude, f.longitude);

        // Route-aware facility filtering (1000m corridor when route active)
        if (isRouteActive && activeRoute != null && activeRoute.geometry.isNotEmpty) {
          if (!_isIncidentNearRoute(facPoint, activeRoute.geometry, proximityMeters: kFacilityProximityThresholdMeters)) {
            continue;
          }
        }

        markers.add(
          gmaps.Marker(
            markerId: gmaps.MarkerId('fac_${f.id}'),
            position: gmaps.LatLng(f.latitude, f.longitude),
            icon: facIcon,
            infoWindow: gmaps.InfoWindow(
              title: f.name,
              snippet: '${f.facilityType.replaceAll("_", " ")} · ${f.phoneNumber ?? ""}',
              onTap: () => _showFacilityDetails(f),
            ),
            onTap: () => _showFacilityDetails(f),
          ),
        );
      }
    }

    _cachedMarkers = markers;
    return markers;
  }

  // Memoized polylines generator
  Set<gmaps.Polyline> _buildMemoizedPolylines() {
    int currentPolylineHash = Object.hash(
      _routes.length,
      _selectedRouteId,
      _recommendedRouteId,
      _routes.isNotEmpty ? _routes.first.geometry.length : 0,
    );

    if (currentPolylineHash == _lastPolylineHash && _cachedPolylines.isNotEmpty) {
      return _cachedPolylines;
    }

    _lastPolylineHash = currentPolylineHash;
    final Set<gmaps.Polyline> polylines = {};

    for (final r in _routes) {
      final isSelected = (r.routeId == _selectedRouteId);
      final isRec = (r.routeId == _recommendedRouteId);

      Color polyColor;
      if (isSelected) {
        polyColor = isRec ? const Color(0xFF2E7D32) : const Color(0xFF00796B);
      } else {
        polyColor = const Color(0xFF90A4AE).withValues(alpha: 0.7);
      }

      polylines.add(
        gmaps.Polyline(
          polylineId: gmaps.PolylineId(r.routeId),
          points: r.geometry
              .map((pt) => gmaps.LatLng(pt.latitude, pt.longitude))
              .toList(),
          color: polyColor,
          width: isSelected ? 6 : 4,
          zIndex: isSelected ? 2 : 1,
          consumeTapEvents: true,
          onTap: () {
            setState(() => _selectedRouteId = r.routeId);
          },
        ),
      );
    }

    _cachedPolylines = polylines;
    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocationService>(context);
    final incidentService = Provider.of<IncidentService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final locService = Provider.of<LocalizationService>(context);
    final isDark = themeService.isDarkMode;
    final incidentsList = incidentService.incidents;
    final facilitiesList = incidentService.facilities;
    final bool isRouteActive = _routes.isNotEmpty;

    final gmapsPolylines = _buildMemoizedPolylines();
    final gmapsMarkers = _buildMemoizedMarkers(
      loc,
      incidentsList,
      facilitiesList,
    );

    final selectedRoute = _routes.firstWhere(
      (r) => r.routeId == _selectedRouteId,
      orElse: () => _routes.isNotEmpty ? _routes.first : RoutingService.demoRoutes.first,
    );
    final activeScore = _scores[_selectedRouteId];

    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double sheetBaseHeight = _isRouteSheetExpanded ? 240.0 : 70.0;
    final double totalSheetOffset = sheetBaseHeight + bottomInset;

    return PopScope(
      canPop: !_isSearchFocused,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && _isSearchFocused) {
          _exitSearchFocus();
        }
      },
      child: Scaffold(
        drawer: _buildAppDrawer(isDark, locService),
        body: Stack(
          children: [
            // 1. Primary Interactive Google Maps Widget
            gmaps.GoogleMap(
              style: isDark && _darkMapStyleJson.isNotEmpty
                  ? _darkMapStyleJson
                  : null,
              initialCameraPosition: const gmaps.CameraPosition(
                target: gmaps.LatLng(AppConfig.defaultLat, AppConfig.defaultLng),
                zoom: 12.5,
              ),
              onMapCreated: (gmaps.GoogleMapController controller) {
                _googleMapController = controller;
              },
              onCameraMove: (gmaps.CameraPosition position) {
                final int newTier = position.zoom < 12.0 ? 0 : (position.zoom < 14.5 ? 1 : 2);
                if (newTier != _currentZoomTier) {
                  setState(() {
                    _currentZoomTier = newTier;
                  });
                }
              },
              onTap: (gmaps.LatLng point) {
                if (_isSearchFocused) {
                  _exitSearchFocus();
                  return;
                }
                _onMapTapped(ll.LatLng(point.latitude, point.longitude));
              },
              polylines: gmapsPolylines,
              markers: gmapsMarkers,
              myLocationEnabled: loc.hasValidGps,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
            ),

            // 2. Clean Top Control Column: Search Bar -> Autocomplete -> Filters -> Legend
            // Dedicated vertical space eliminates all overlaps
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A. Search Bar Container
                  _buildSearchBarContainer(isDark, loc, locService),

                  // B. Photon Autocomplete Suggestions Dropdown
                  if (_searchSuggestions.isNotEmpty)
                    _buildSearchSuggestionsDropdown(isDark),

                  // C. Horizontal Category Filter Chips & Legend (hidden during Search Focus Mode)
                  if (!_isSearchFocused) ...[
                    const SizedBox(height: 8),
                    _buildCategoryFiltersRow(isDark, locService),
                    const SizedBox(height: 6),
                    _buildColorLegend(
                      isDark,
                      incidentsList,
                      facilitiesList,
                      locService,
                      isRouteActive,
                    ),
                  ],
                ],
              ),
            ),

            // 3. Right-side Map Action Controls (Zoom in, Zoom out, My Location, Facilities)
            // Responsive to bottom sheet expansion via AnimatedPositioned; hidden during Search Focus Mode
            if (!_isSearchFocused)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                right: 12,
                bottom: totalSheetOffset + 38,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMapControlBtn(
                      icon: Icons.add,
                      tooltip: locService.t('zoom_in'),
                      onTap: _zoomIn,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildMapControlBtn(
                      icon: Icons.remove,
                      tooltip: locService.t('zoom_out'),
                      onTap: _zoomOut,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildMapControlBtn(
                      icon: Icons.my_location,
                      tooltip: locService.t('my_location'),
                      color: const Color(0xFF00897B),
                      onTap: _centerOnCurrentLocation,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildMapControlBtn(
                      icon: _showFacilities ? Icons.domain : Icons.domain_disabled,
                      tooltip: locService.t('toggle_facilities'),
                      color: _showFacilities ? const Color(0xFF1A237E) : Colors.grey,
                      onTap: () => setState(() => _showFacilities = !_showFacilities),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

            // 4. Map Attribution Pill (Bottom-Right, fully visible and unobstructed)
            // Responsive to bottom sheet expansion via AnimatedPositioned; hidden during Search Focus Mode
            if (!_isSearchFocused)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                right: 12,
                bottom: totalSheetOffset + 8,
                child: _buildAttributionPill(isDark),
              ),

            // 5. Floating Action Buttons (Mic & Report - Left side above sheet)
            // Responsive to bottom sheet expansion via AnimatedPositioned; hidden during Search Focus Mode
            if (!_isSearchFocused)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: 12,
                bottom: totalSheetOffset + 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'fab_voice',
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      tooltip: locService.t('ask_suraksha'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AssistantScreen(autoStartListening: true),
                          ),
                        );
                      },
                      child: const Icon(Icons.mic, size: 20),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.extended(
                      heroTag: 'fab_report',
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                      label: Text(
                        locService.t('report_hazard'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReportIncidentScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            // 6. Persistent Route Planning Action Sheet (Bottom) - Hidden during Search Focus Mode
            if (!_isSearchFocused)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildRoutePlanningSheet(
                  loc,
                  selectedRoute,
                  activeScore,
                  isDark,
                  locService,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Subcomponents for Clean Layout ---

  Widget _buildSearchBarContainer(bool isDark, LocationService loc, LocalizationService locService) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C33) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF223055) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading)
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(2)),
              child: LinearProgressIndicator(
                minHeight: 2.5,
                color: Color(0xFF00796B),
                backgroundColor: Colors.transparent,
              ),
            ),

          // Mode Selector Row: Destination vs Origin
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _isSearchingOrigin = false;
                    _searchController.clear();
                    _searchSuggestions = [];
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: !_isSearchingOrigin
                          ? const Color(0xFF00796B)
                          : (isDark ? const Color(0xFF18223E) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.place,
                          size: 12,
                          color: !_isSearchingOrigin ? Colors.white : const Color(0xFFC62828),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          locService.t('destination_label'),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: !_isSearchingOrigin ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    _isSearchingOrigin = true;
                    _searchController.clear();
                    _searchSuggestions = [];
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isSearchingOrigin
                          ? const Color(0xFF00796B)
                          : (isDark ? const Color(0xFF18223E) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trip_origin,
                          size: 12,
                          color: _isSearchingOrigin ? Colors.white : const Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          locService.t('origin_label'),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: _isSearchingOrigin ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Swap button
                IconButton(
                  icon: const Icon(Icons.swap_vert, size: 18),
                  tooltip: locService.t('swap_direction'),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    loc.swapOriginDestination();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Swapped: ${loc.origin} ⇄ ${loc.destination}'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),

          // Text Field Row
          Row(
            children: [
              if (_isSearchFocused)
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? const Color(0xFF4DB6AC) : const Color(0xFF1A237E),
                  ),
                  tooltip: 'Exit Search',
                  onPressed: _exitSearchFocus,
                )
              else
                Builder(
                  builder: (ctx) => IconButton(
                    icon: Icon(
                      Icons.menu,
                      color: isDark ? const Color(0xFF4DB6AC) : const Color(0xFF1A237E),
                    ),
                    tooltip: 'Open Menu',
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onTap: () {
                    if (!_isSearchFocused) {
                      setState(() => _isSearchFocused = true);
                    }
                  },
                  onChanged: _onSearchChanged,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: _isSearchingOrigin
                        ? locService.t('search_origin_placeholder')
                        : 'Search places via Photon (Hyderabad)...',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.grey.shade400 : Colors.grey,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                  tooltip: 'Clear Search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchSuggestions = []);
                  },
                ),
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00796B),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.search, color: Color(0xFF00796B)),
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      _onSearchChanged(_searchController.text);
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestionsDropdown(bool isDark) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final topPadding = mediaQuery.padding.top;
    final screenHeight = mediaQuery.size.height;
    final double availableHeight = screenHeight - keyboardHeight - (topPadding + 110);
    final double maxHeight = max(140.0, min(availableHeight, 340.0));

    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C33) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF223055) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: _searchSuggestions.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: isDark ? const Color(0xFF223055) : const Color(0xFFE2E8F0),
        ),
        itemBuilder: (context, idx) {
          final item = _searchSuggestions[idx];
          return ListTile(
            dense: true,
            leading: Icon(
              _isSearchingOrigin ? Icons.trip_origin : Icons.place_outlined,
              size: 18,
              color: _isSearchingOrigin ? const Color(0xFF2E7D32) : const Color(0xFF00796B),
            ),
            title: Text(
              item.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            subtitle: Text(
              item.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
            onTap: () => _selectSearchSuggestion(item),
          );
        },
      ),
    );
  }

  Widget _buildCategoryFiltersRow(bool isDark, LocalizationService locService) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categoryFilterOptions.map((cat) {
          final isSel = _selectedCategoryFilter == cat;
          String label = cat == 'ALL' ? locService.t('all_incidents') : cat.replaceAll('_', ' ');
          if (cat == 'ROAD_ACCIDENT') label = 'Road Accidents';
          if (cat == 'WOMEN_SAFETY') label = "Women's Safety";
          if (cat == 'POOR_STREET_LIGHTING') label = 'Poor Lighting';
          if (cat == 'TRAFFIC_HAZARD') label = 'Traffic Hazards';
          if (cat == 'ROAD_OBSTRUCTION') label = 'Obstructions';

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? Colors.white : (isDark ? Colors.grey.shade300 : const Color(0xFF1A237E)),
                ),
              ),
              selected: isSel,
              selectedColor: const Color(0xFF00796B),
              backgroundColor: isDark ? const Color(0xFF141C33) : Colors.white,
              side: BorderSide(
                color: isSel ? const Color(0xFF00796B) : (isDark ? const Color(0xFF223055) : const Color(0xFFCFD8DC)),
                width: 0.8,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              visualDensity: VisualDensity.compact,
              onSelected: (_) => _onFilterChanged(cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttributionPill(bool isDark) {
    return GestureDetector(
      onTap: _showStackInfoDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF141C33) : Colors.white).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? const Color(0xFF223055) : Colors.black12,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 10,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 4),
            Text(
              'Google Maps SDK · OSRM · ',
              style: TextStyle(
                fontSize: 8.5,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            Text(
              '© OpenStreetMap contributors',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
    required bool isDark,
  }) {
    final effectiveColor = color ?? (isDark ? Colors.white : Colors.black87);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C33) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF223055) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: effectiveColor, size: 20),
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildColorLegend(
    bool isDark,
    List<IncidentModel> incidents,
    List<PublicFacilityModel> facilities,
    LocalizationService locService,
    bool isRouteActive,
  ) {
    int countCategory(String cat) =>
        incidents.where((i) => i.category == cat).length;
    final int accCount = countCategory('ROAD_ACCIDENT');
    final int womenCount =
        countCategory('WOMEN_SAFETY') + countCategory('HARASSMENT');
    final int lightCount = countCategory('POOR_STREET_LIGHTING');
    final int hazardCount =
        countCategory('TRAFFIC_HAZARD') + countCategory('ROAD_OBSTRUCTION');
    final int policeCount = facilities
        .where((f) => f.facilityType == 'POLICE_STATION')
        .length;
    final int sheHubCount = facilities
        .where((f) => f.facilityType == 'WOMEN_SAFETY_HUB')
        .length;
    final int hospCount = facilities
        .where((f) => f.facilityType == 'HOSPITAL_EMERGENCY')
        .length;

    final String badgeLabel = isRouteActive
        ? '${_cachedMarkers.length} Along Route'
        : '${incidents.length + facilities.length} Pins';

    if (!_isLegendExpanded) {
      return GestureDetector(
        onTap: () => setState(() => _isLegendExpanded = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF141C33) : Colors.white).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF223055) : const Color(0xFFCFD8DC),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFD32F2F))),
              const SizedBox(width: 4),
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF8E24AA))),
              const SizedBox(width: 4),
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFBC02D))),
              const SizedBox(width: 6),
              Text(
                badgeLabel,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isRouteActive ? const Color(0xFF00796B) : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 14),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 230,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF141C33) : Colors.white).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF223055) : const Color(0xFFCFD8DC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_outlined, size: 14, color: Color(0xFF00796B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  locService.t('legend_title'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isLegendExpanded = false),
                child: const Icon(Icons.close, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildLegendRow(const Color(0xFFD32F2F), 'Road Accident Blackspot', accCount, 'ROAD_ACCIDENT'),
          _buildLegendRow(const Color(0xFF8E24AA), "Women's Safety Concern", womenCount, 'WOMEN_SAFETY'),
          _buildLegendRow(const Color(0xFFFBC02D), 'Poor Street Lighting', lightCount, 'POOR_STREET_LIGHTING'),
          _buildLegendRow(const Color(0xFFF57C00), 'Traffic Hazard / Curve', hazardCount, 'TRAFFIC_HAZARD'),
          _buildLegendRow(const Color(0xFF0097A7), 'Police Stations & ER', policeCount + sheHubCount + hospCount, null),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String label, int count, String? filterCategory) {
    final isSelected = filterCategory != null && _selectedCategoryFilter == filterCategory;
    return GestureDetector(
      onTap: () {
        if (filterCategory != null) {
          setState(() {
            _selectedCategoryFilter = (_selectedCategoryFilter == filterCategory) ? 'ALL' : filterCategory;
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF00897B) : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutePlanningSheet(
    LocationService loc,
    RouteModel route,
    RouteScoreModel? score,
    bool isDark,
    LocalizationService locService,
  ) {
    final sheetBg = isDark ? const Color(0xFF141C33) : Colors.white;

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF223055) : const Color(0xFFE2E8F0),
              width: 0.8,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle to toggle collapse
            GestureDetector(
              onTap: () => setState(
                () => _isRouteSheetExpanded = !_isRouteSheetExpanded,
              ),
              child: Container(
                width: 38,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Inline Routing Progress Indicator (Non-blocking)
            if (_isRouting)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: Color(0xFF00796B),
                        backgroundColor: Color(0xFFB2DFDB),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locService.t('routing_in_progress'),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF00796B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Origin & Destination Summary Bar
            Row(
              children: [
                const Icon(
                  Icons.trip_origin,
                  size: 14,
                  color: Color(0xFF2E7D32),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc.origin,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
                const SizedBox(width: 6),
                const Icon(Icons.place, size: 14, color: Color(0xFFC62828)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    loc.destination,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isRouteSheetExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(
                    () => _isRouteSheetExpanded = !_isRouteSheetExpanded,
                  ),
                ),
              ],
            ),

            if (_isRouteSheetExpanded) ...[
              const SizedBox(height: 8),

              // STATE 1: NO ROUTE ACTIVE YET -> Single Primary "Plan Road Route (OSRM)" Action
              if (_routes.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    locService.t('select_destination_prompt'),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _isRouting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.alt_route, size: 18),
                    label: Text(
                      _isRouting
                          ? locService.t('routing_in_progress')
                          : 'Plan Road Route (OSRM)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isRouting
                        ? null
                        : () => _planRoadRoute(loc.originCoords, loc.destinationCoords),
                  ),
                ),
              ]
              // STATE 2: ROUTE ACTIVE -> Candidate Route Selector & Google Maps Launch
              else ...[
                // Route Tabs (e.g. Route A, Route B)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _routes.map((r) {
                      final isSel = (r.routeId == _selectedRouteId);
                      final isRec = (r.routeId == _recommendedRouteId);
                      final rScore = _scores[r.routeId];

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isRec) ...[
                                const Icon(Icons.star, size: 12, color: Colors.amber),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                r.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              if (rScore != null) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    rScore.score.toStringAsFixed(0),
                                    style: const TextStyle(fontSize: 9, color: Colors.white),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          selected: isSel,
                          selectedColor: const Color(0xFF00796B),
                          backgroundColor: isDark ? const Color(0xFF18223E) : const Color(0xFFF1F5F9),
                          onSelected: (_) {
                            setState(() => _selectedRouteId = r.routeId);
                            _fitRouteBounds(r.geometry);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // Metrics Row (Distance, Duration & Score)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18223E) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF223055) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${route.distanceKm.toStringAsFixed(1)} ${locService.t("km")} • ${route.durationMinutes} ${locService.t("mins")}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              route.summary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showWhyThisScoreDialog(route, score),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA5D6A7)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shield_outlined, color: Color(0xFF2E7D32), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${score?.score.toStringAsFixed(0) ?? "28"}/100',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.info_outline, size: 11, color: Color(0xFF2E7D32)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Action Buttons: Navigate with Google Maps, Recalculate & Clear
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.navigation, size: 15),
                        label: Text(
                          locService.t('navigate_google_maps'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          NavigationLauncherService.launchGoogleMapsNavigation(
                            context: context,
                            destination: loc.destinationCoords,
                            origin: loc.originCoordsNullable,
                            isOriginCurrentLocation: loc.usingCurrentLocation,
                            destinationName: loc.destination,
                            originName: loc.origin,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: locService.t('recalculate_route'),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF18223E) : const Color(0xFFF1F5F9),
                      ),
                      onPressed: () => _planRoadRoute(loc.originCoords, loc.destinationCoords),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                      tooltip: locService.t('clear_route'),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF18223E) : const Color(0xFFF1F5F9),
                      ),
                      onPressed: _clearRoute,
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppDrawer(bool isDark, LocalizationService locService) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0D1326) : Colors.white,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            color: const Color(0xFF1A237E),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFF00897B),
                  child: Icon(Icons.shield, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locService.t('menu_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        locService.t('menu_subtitle'),
                        style: const TextStyle(
                          color: Color(0xFF80CBC4),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.map_outlined, color: Color(0xFF00897B)),
                  title: Text(locService.t('nav_map')),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.support_agent_outlined, color: Color(0xFF1A237E)),
                  title: Text(locService.t('nav_assistant')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AssistantScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report_problem_outlined, color: Color(0xFFE65100)),
                  title: Text(locService.t('nav_report')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReportIncidentScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assignment_outlined, color: Color(0xFF0288D1)),
                  title: Text(locService.t('nav_my_reports')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyReportsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark_border, color: Color(0xFF7B1FA2)),
                  title: Text(locService.t('nav_saved_places')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SavedLocationsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Color(0xFF455A64)),
                  title: Text(locService.t('nav_methodology')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScoreExplanationScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings_outlined, color: Color(0xFF546E7A)),
                  title: Text(locService.t('nav_settings')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141C33) : const Color(0xFFF1F5F9),
              border: Border(top: BorderSide(color: isDark ? const Color(0xFF223055) : const Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        locService.t('nav_emergency'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      const Text(
                        'Direct emergency dispatch in Telangana',
                        style: TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    EmergencyService.promptAndLaunchHelpline(
                      context,
                      number: EmergencyService.nationalEmergencyNumber,
                      title: locService.t('helpline_112'),
                      description: 'Connect directly to Police, Fire, or Ambulance dispatch in Telangana.',
                    );
                  },
                  child: const Text('112', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    EmergencyService.promptAndLaunchHelpline(
                      context,
                      number: EmergencyService.womenHelplineNumber,
                      title: locService.t('helpline_1091'),
                      description: 'Connect directly to 24x7 Women Safety Wing / SHE Teams assistance.',
                    );
                  },
                  child: const Text('1091', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
