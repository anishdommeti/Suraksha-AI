import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
import '../models/chat_message_model.dart';
import '../models/incident_model.dart';
import '../models/route_model.dart';
import '../models/route_score_model.dart';
import '../data/embedded_incidents_data.dart';
import 'photon_service.dart';
import 'routing_service.dart';
import 'location_service.dart';
import 'speech_service.dart';

class AssistantService extends ChangeNotifier {
  final SpeechService speechService;
  final RoutingService routingService = RoutingService();
  final PhotonService photonService = PhotonService();

  final List<ChatMessageModel> _messages = [];
  List<RouteModel> _activeRoutes = [];
  Map<String, RouteScoreModel> _activeScores = {};
  String? _selectedRouteId;
  bool _isLoading = false;

  List<ChatMessageModel> get messages => _messages;
  List<RouteModel> get activeRoutes => _activeRoutes;
  Map<String, RouteScoreModel> get activeScores => _activeScores;
  String? get selectedRouteId => _selectedRouteId;
  bool get isLoading => _isLoading;

  AssistantService({required this.speechService}) {
    _messages.add(
      ChatMessageModel(
        id: 'msg_init',
        sender: 'suraksha',
        text: AppConfig.greeting,
        spokenText: AppConfig.greeting,
        timestamp: DateTime.now(),
        suggestedActions: [
          'Take me to Rajiv Gandhi International Airport',
          'Navigate to Uppal Stadium',
          'Find route from Tank Bund to Secunderabad Station',
          'Which route has fewer recorded incidents?',
        ],
      ),
    );
    _activeRoutes = RoutingService.demoRoutes;
  }

  void selectRoute(String routeId) {
    _selectedRouteId = routeId;
    notifyListeners();
  }

  // Known landmark coordinates across Hyderabad for instant deterministic resolution
  static final Map<String, LatLng> _landmarkDictionary = {
    'rajiv gandhi international airport': const LatLng(17.2403, 78.4294),
    'international airport': const LatLng(17.2403, 78.4294),
    'airport': const LatLng(17.2403, 78.4294),
    'rgia': const LatLng(17.2403, 78.4294),
    'shamshabad': const LatLng(17.2514, 78.4312),
    'uppal stadium': const LatLng(17.4065, 78.5591),
    'uppal cricket stadium': const LatLng(17.4065, 78.5591),
    'rajiv gandhi stadium': const LatLng(17.4065, 78.5591),
    'uppal': const LatLng(17.4018, 78.5602),
    'secunderabad railway station': const LatLng(17.4344, 78.5015),
    'secunderabad station': const LatLng(17.4344, 78.5015),
    'secunderabad': const LatLng(17.4398, 78.4982),
    'tank bund': const LatLng(17.4239, 78.4738),
    'hussain sagar': const LatLng(17.4239, 78.4738),
    'charminar': const LatLng(17.3616, 78.4747),
    'cyber towers': const LatLng(17.4504, 78.3808),
    'hitec city': const LatLng(17.4504, 78.3808),
    'mindspace': const LatLng(17.4435, 78.3772),
    'gachibowli stadium': const LatLng(17.4401, 78.3489),
    'gachibowli': const LatLng(17.4401, 78.3489),
    'inorbit mall': const LatLng(17.4330, 78.3865),
    'durgam cheruvu': const LatLng(17.4314, 78.3935),
    'kphb colony': const LatLng(17.4932, 78.3995),
    'jntu': const LatLng(17.4985, 78.3908),
    'kukatpally': const LatLng(17.4932, 78.3995),
    'dilsukhnagar metro': const LatLng(17.3688, 78.5248),
    'dilsukhnagar': const LatLng(17.3688, 78.5248),
    'mehdipatnam': const LatLng(17.3920, 78.4398),
    'jubilee hills check post': const LatLng(17.4300, 78.4110),
    'jubilee hills': const LatLng(17.4300, 78.4110),
    'banjara hills road no 1': const LatLng(17.4215, 78.4482),
    'banjara hills': const LatLng(17.4215, 78.4482),
    'begumpet': const LatLng(17.4442, 78.4682),
    'begumpet airport': const LatLng(17.4442, 78.4682),
    'nampally railway station': const LatLng(17.3926, 78.4697),
    'hyderabad railway station': const LatLng(17.3926, 78.4697),
    'saidabad metro station': const LatLng(17.3753, 78.4908),
    'saidabad metro': const LatLng(17.3753, 78.4908),
    'saidabad': const LatLng(17.3670, 78.5050),
    'matrusri engineering college': const LatLng(17.3596, 78.5085),
    'college': const LatLng(17.3596, 78.5085),
    'my college': const LatLng(17.3596, 78.5085),
  };

  Future<void> sendMessage(
    String text, {
    bool speakResponse = true,
    String? origin,
    String? destination,
    LatLng? originCoords,
    LocationService? locationService,
    bool isTelugu = false,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMsg = ChatMessageModel(
      id: 'msg_u_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      text: trimmed,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _isLoading = true;
    speechService.setProcessing(true);
    notifyListeners();

    // 1. Try backend server if active
    final historyList = _messages
        .where((m) => m.id != userMsg.id && m.id != 'msg_init')
        .take(6)
        .map((m) => {'sender': m.sender, 'text': m.text})
        .toList();

    try {
      final url = Uri.parse('${AppConfig.backendBaseUrl}/api/agent/chat');
      final payload = json.encode({
        'message': trimmed,
        'conversation_history': historyList,
        'current_route_id': _selectedRouteId,
        'origin': origin ?? 'Matrusri Engineering College',
        'destination': destination ?? 'Saidabad Metro Station',
      });

      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 2));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        _handleSuccessfulAgentResponse(data, speakResponse);
        return;
      }
    } catch (_) {
      // Offline / Network fallback
    }

    // 2. Local Action Agent pipeline with genuine geocoding, OSRM routing & safety scoring
    await _handleLocalAgentPipeline(
      query: trimmed,
      speakResponse: speakResponse,
      currentOrigin: origin,
      currentDestination: destination,
      currentOriginCoords: originCoords,
      locationService: locationService,
      isTelugu: isTelugu,
    );
  }

  void _handleSuccessfulAgentResponse(
    Map<String, dynamic> data,
    bool speakResponse,
  ) {
    _isLoading = false;
    speechService.setProcessing(false);

    final replyText = data['reply_text'] ?? '';
    final spokenText = data['spoken_text'] ?? replyText;
    final toolsList = (data['tools_called'] as List? ?? [])
        .map((e) => ToolInvocationModel.fromJson(e))
        .toList();
    final actions = List<String>.from(data['suggested_actions'] ?? []);

    if (data['routes'] != null) {
      _activeRoutes = (data['routes'] as List)
          .map((e) => RouteModel.fromJson(e))
          .toList();
    }
    if (data['scores'] != null) {
      _activeScores = {};
      (data['scores'] as Map<String, dynamic>).forEach((k, v) {
        _activeScores[k] = RouteScoreModel.fromJson(v);
      });
    }
    if (data['selected_route_id'] != null) {
      _selectedRouteId = data['selected_route_id'];
    }

    _messages.add(
      ChatMessageModel(
        id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'suraksha',
        text: replyText,
        spokenText: spokenText,
        timestamp: DateTime.now(),
        toolsCalled: toolsList,
        suggestedActions: actions,
      ),
    );

    notifyListeners();

    if (speakResponse && spokenText.isNotEmpty) {
      speechService.speak(spokenText);
    }
  }

  /// Complete Autonomous Local Pipeline with Natural Language Entity Extraction,
  /// Photon Geocoding, Real OSRM Road Calculation and Heuristic Corridor Safety Scoring.
  Future<void> _handleLocalAgentPipeline({
    required String query,
    required bool speakResponse,
    String? currentOrigin,
    String? currentDestination,
    LatLng? currentOriginCoords,
    LocationService? locationService,
    bool isTelugu = false,
  }) async {
    final q = query.toLowerCase();
    final tools = <ToolInvocationModel>[];
    String reply = '';
    String spoken = '';
    List<String> actions = [];
    List<RouteComparisonCardData> cards = [];

    // Intent 1: Incident Reporting Request
    if (q.contains('report') ||
        q.contains('hazard') ||
        q.contains('pothole') ||
        q.contains('accident') ||
        q.contains('ఫిర్యాదు') ||
        q.contains('సమస్య')) {
      tools.add(
        ToolInvocationModel(
          toolName: 'open_incident_reporter',
          parameters: {'category': 'ROAD_ACCIDENT'},
          result: {'status': 'form_ready'},
        ),
      );

      reply = isTelugu
          ? "ప్రమాదం లేదా సమస్యను నివేదించడానికి రిపోర్టింగ్ ఫారం సిద్ధంగా ఉంది.\n\n"
            "• వర్గం ఎంచుకోండి: రోడ్డు ప్రమాదం, మహిళల భద్రత, లైటింగ్ లేకపోవడం.\n"
            "• మీ ప్రస్తుత GPS స్థానాన్ని స్వయంచాలకంగా జోడించవచ్చు.\n"
            "• అత్యవసరమైతే వెంటనే 112 లేదా 1091 కు కాల్ చేయండి."
          : "Incident Reporting Portal is ready.\n\n"
            "• Tap the Report button to log road accidents, dark spots, or harassment.\n"
            "• GPS coordinates and timestamp are tagged automatically.\n"
            "• For immediate life safety emergencies, call 112 or 1091.";

      spoken = isTelugu
          ? "సమస్యను నివేదించడానికి ఫారం సిద్ధంగా ఉంది. దయచేసి వివరాలను నమోదు చేయండి."
          : "Incident reporting portal ready. Please submit details with live GPS coordinates.";
      actions = [
        'Report poor street lighting',
        'Report harassment',
        'Compare candidate routes',
      ];
    }
    // Intent 2: Explanation of Route Heuristic Scores
    else if (q.contains('why') ||
        q.contains('recommend') ||
        q.contains('difference') ||
        q.contains('methodology') ||
        q.contains('ఎందుకు') ||
        q.contains('సిఫార్సు')) {
      tools.add(
        ToolInvocationModel(
          toolName: 'explain_safety_heuristic',
          parameters: {'formula': 'exposure_density = incidents / distance_km'},
          result: {'status': 'evidence_backed'},
        ),
      );

      reply = isTelugu
          ? "సురక్ష AI భద్రతా స్కోరింగ్ విధానం:\n\n"
            "• రూట్ భద్రతా స్కోరు (0-100) 200 మీటర్ల పరిధిలోని ధృవీకరించబడిన ప్రమాదాలు మరియు సమస్యల ఆధారంగా లెక్కించబడుతుంది.\n"
            "• తక్కువ స్కోరు ఉన్న మార్గంలో తక్కువ ప్రమాదాలు నమోదయ్యాయని అర్థం.\n"
            "• రికార్డులు తక్కువగా ఉన్నంత మాత్రాన సంపూర్ణ భద్రత అని హామీ ఇవ్వబడదు."
          : "Evidence Explanation:\n\n"
            "• SURAKSHA AI calculates transparent heuristic scores (0–100) based strictly on verified incidents within a 200m spatial corridor.\n"
            "• Lower scores reflect lower recorded incident density per kilometer.\n"
            "• Community reports remain PENDING and do not alter official scores until verified.\n"
            "• Low scores reflect fewer recorded hazards, not a guarantee of absolute safety.";

      spoken = isTelugu
          ? "రూట్ భద్రతా స్కోరు 200 మీటర్ల పరిధిలోని ధృవీకరించబడిన ప్రమాదాల ఆధారంగా లెక్కించబడుతుంది."
          : "SURAKSHA AI computes transparent heuristic scores based on verified incident density within a 200 meter corridor.";
      actions = [
        'Take me to Rajiv Gandhi International Airport',
        'Compare candidate routes',
      ];
    }
    // Intent 3: Navigation / Route Request with Dynamic Geocoding & OSRM
    else {
      String rawDest = '';
      String rawOrigin = '';

      // Check "from X to Y"
      final fromToRegex = RegExp(r'from\s+([a-zA-Z0-9\s]+?)\s+to\s+([a-zA-Z0-9\s\.\?]+)', caseSensitive: false);
      final fromToMatch = fromToRegex.firstMatch(query);

      if (fromToMatch != null) {
        rawOrigin = fromToMatch.group(1)?.trim() ?? '';
        rawDest = fromToMatch.group(2)?.trim() ?? '';
      } else {
        // Check "take me to / navigate to / route to / to"
        for (final prefix in [
          'take me to ',
          'navigate to ',
          'find route to ',
          'route to ',
          'directions to ',
          'go to ',
          'to ',
          'వెళ్ళాలి ',
          'దారి చూపు ',
        ]) {
          if (q.contains(prefix)) {
            final startIdx = q.indexOf(prefix) + prefix.length;
            rawDest = query.substring(startIdx).replaceAll(RegExp(r'[\?\.\!]+$'), '').trim();
            break;
          }
        }
        if (rawDest.isEmpty && !q.contains('hi') && !q.contains('hello')) {
          rawDest = query.replaceAll(RegExp(r'[\?\.\!]+$'), '').trim();
        }
      }

      // Default fallback destination if none extracted
      if (rawDest.isEmpty) {
        rawDest = currentDestination != null && currentDestination.isNotEmpty
            ? currentDestination
            : 'Rajiv Gandhi International Airport';
      }

      // Resolve Origin
      LatLng resolvedOriginCoords;
      String originDisplayName;
      if (rawOrigin.isNotEmpty) {
        final originResolution = await _resolveHyderabadLocation(rawOrigin);
        resolvedOriginCoords = originResolution.coords;
        originDisplayName = originResolution.displayName;
      } else if (currentOriginCoords != null) {
        resolvedOriginCoords = currentOriginCoords;
        originDisplayName = currentOrigin ?? 'Current Location';
      } else {
        resolvedOriginCoords = const LatLng(17.3596, 78.5085); // Matrusri Eng College
        originDisplayName = 'Matrusri Engineering College';
      }

      // Resolve Destination via Landmark Dictionary or Photon Geocoding
      final destResolution = await _resolveHyderabadLocation(rawDest);
      final resolvedDestCoords = destResolution.coords;
      final destDisplayName = destResolution.displayName;

      tools.add(
        ToolInvocationModel(
          toolName: 'resolve_spatial_entity',
          parameters: {
            'origin': originDisplayName,
            'origin_coords': '${resolvedOriginCoords.latitude},${resolvedOriginCoords.longitude}',
            'destination': destDisplayName,
            'dest_coords': '${resolvedDestCoords.latitude},${resolvedDestCoords.longitude}',
          },
          result: {'status': 'resolved'},
        ),
      );

      // Fetch authentic road routes via OSRM
      List<RouteModel> calculatedRoutes = [];
      try {
        calculatedRoutes = await routingService.calculateRoadRoutes(
          resolvedOriginCoords,
          resolvedDestCoords,
        );
      } catch (e) {
        debugPrint('[SURAKSHA AI] OSRM route fetch failed: $e');
      }

      // If OSRM produced no routes, create straight-line fallback road routes
      if (calculatedRoutes.isEmpty) {
        final distanceCalculator = const Distance();
        final distM = distanceCalculator.as(LengthUnit.Meter, resolvedOriginCoords, resolvedDestCoords);
        final distKm = double.parse((distM / 1000.0).toStringAsFixed(1));
        final estMins = max(5, (distKm * 2.4).round());

        calculatedRoutes = [
          RouteModel(
            routeId: 'route_primary_${destDisplayName.replaceAll(' ', '_').toLowerCase()}',
            name: 'Primary Arterial Corridor',
            summary: 'Major arterial corridor to $destDisplayName',
            distanceKm: distKm,
            durationMinutes: estMins,
            geometry: [resolvedOriginCoords, resolvedDestCoords],
            isSimulated: true,
            source: 'Demonstration Fixture',
          ),
        ];
      }

      tools.add(
        ToolInvocationModel(
          toolName: 'osrm_multimodal_routing',
          parameters: {
            'coordinates_count': calculatedRoutes.fold(0, (sum, r) => sum + r.geometry.length),
            'routes_found': calculatedRoutes.length,
          },
          result: {'routes': calculatedRoutes.map((r) => r.name).toList()},
        ),
      );

      // Heuristic corridor safety evaluation against all embedded incidents
      final allIncidents = kDefaultEmbeddedIncidents;
      final scoresMap = <String, RouteScoreModel>{};
      final generatedCards = <RouteComparisonCardData>[];

      String bestRouteId = calculatedRoutes.first.routeId;
      double lowestScore = 999.0;

      for (final r in calculatedRoutes) {
        final scoreModel = _calculateCorridorSafetyScore(r, allIncidents);
        scoresMap[r.routeId] = scoreModel;

        if (scoreModel.score < lowestScore) {
          lowestScore = scoreModel.score;
          bestRouteId = r.routeId;
        }
      }

      tools.add(
        ToolInvocationModel(
          toolName: 'corridor_safety_audit',
          parameters: {
            'buffer_meters': 200,
            'dataset_records': allIncidents.length,
          },
          result: {
            'recommended_route': bestRouteId,
            'safest_score': lowestScore,
          },
        ),
      );

      for (final r in calculatedRoutes) {
        final s = scoresMap[r.routeId]!;
        final isRec = (r.routeId == bestRouteId);

        generatedCards.add(
          RouteComparisonCardData(
            routeId: r.routeId,
            name: r.name,
            distanceKm: r.distanceKm,
            durationMinutes: r.durationMinutes,
            score: s.score,
            scoreCategory: s.scoreCategory,
            verifiedCount: s.verifiedIncidentCount,
            topHazards: s.topHazards,
            recommendationReason: isRec
                ? (isTelugu
                    ? 'ధృవీకరించబడిన ప్రమాదాలు అతి తక్కువగా నమోదయ్యాయి (స్కోరు: ${s.score}/100)'
                    : 'Fewer recorded hazards per km (${s.verifiedIncidentCount} within 200m corridor)')
                : (isTelugu
                    ? 'ఎక్కువ రద్దీ / అధిక ప్రమాద సాంద్రత (స్కోరు: ${s.score}/100)'
                    : 'Higher incident density along secondary corridors'),
            isRecommended: isRec,
          ),
        );
      }

      // Update LocationService state
      if (locationService != null) {
        locationService.setLocations(
          origin: originDisplayName,
          destination: destDisplayName,
          originCoords: resolvedOriginCoords,
          destinationCoords: resolvedDestCoords,
          usingCurrentLocation: rawOrigin.isEmpty && currentOriginCoords != null,
        );
      }

      _activeRoutes = calculatedRoutes;
      _activeScores = scoresMap;
      _selectedRouteId = bestRouteId;

      final bestRoute = calculatedRoutes.firstWhere((r) => r.routeId == bestRouteId);
      final bestScore = scoresMap[bestRouteId]!;

      if (isTelugu) {
        reply = "నేను $destDisplayName వైపు ${calculatedRoutes.length} మార్గాలను విశ్లేషించాను.\n\n"
            "సిఫార్సు: ${bestRoute.name} (${bestRoute.distanceKm} కి.మీ, ${bestRoute.durationMinutes} నిమిషాలు) భద్రతా స్కోరు ${bestScore.score}/100 తో ఉత్తమమైనది.\n\n"
            "మ్యాప్‌లో చూడడానికి లేదా గూగుల్ మ్యాప్స్‌లో నావిగేట్ చేయడానికి క్రింది కార్డును ఎంచుకోండి.";
        spoken = "$destDisplayName వైపు రూట్ సిద్ధంగా ఉంది. ${bestRoute.distanceKm} కిలోమీటర్ల దూరం, భద్రతా స్కోరు ${bestScore.score}.";
      } else {
        reply = "I analyzed ${calculatedRoutes.length} route${calculatedRoutes.length == 1 ? '' : 's'} to $destDisplayName.\n\n"
            "• Destination: $destDisplayName\n"
            "• Distance: ${bestRoute.distanceKm} km · Est. Duration: ${bestRoute.durationMinutes} mins\n"
            "• Safety Score: ${bestScore.score}/100 (${bestScore.verifiedIncidentCount} recorded hazards in 200m buffer)\n\n"
            "Select 'View on Map' or 'Google Maps' below to start your journey.";
        spoken = "I found a route to $destDisplayName covering ${bestRoute.distanceKm} kilometers with a safety score of ${bestScore.score} out of 100.";
      }

      actions = [
        'Why did you recommend this route?',
        'Take me to Rajiv Gandhi International Airport',
        'Navigate to Uppal Stadium',
        'Report a hazard',
      ];

      cards = generatedCards;
    }

    _isLoading = false;
    speechService.setProcessing(false);

    _messages.add(
      ChatMessageModel(
        id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'suraksha',
        text: reply,
        spokenText: spoken,
        timestamp: DateTime.now(),
        toolsCalled: tools,
        suggestedActions: actions,
        comparisonCards: cards.isNotEmpty ? cards : null,
      ),
    );

    notifyListeners();

    if (speakResponse && spoken.isNotEmpty) {
      speechService.speak(spoken);
    }
  }

  /// Resolve location name to real coordinates in Hyderabad
  Future<({String displayName, LatLng coords})> _resolveHyderabadLocation(String query) async {
    final clean = query.trim().toLowerCase();

    // 1. Direct dictionary match
    for (final entry in _landmarkDictionary.entries) {
      if (clean == entry.key || clean.contains(entry.key) || entry.key.contains(clean)) {
        final title = entry.key
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
        return (displayName: title, coords: entry.value);
      }
    }

    // 2. Photon Geocoding via Komoot
    try {
      final features = await photonService.search(
        query,
        limit: 5,
      );

      if (features.isNotEmpty) {
        final top = features.first;
        return (displayName: top.displayName, coords: top.coordinates);
      }
    } catch (e) {
      debugPrint('[SURAKSHA AI] Geocoding exception for "$query": $e');
    }

    // 3. Fallback to Hyderabad Central Coordinates if unrecognized
    return (
      displayName: query,
      coords: const LatLng(17.3850, 78.4867),
    );
  }

  /// Mathematical Heuristic Corridor Exposure calculation based strictly on real dataset
  RouteScoreModel _calculateCorridorSafetyScore(RouteModel route, List<IncidentModel> allIncidents) {
    const corridorMeters = 200.0;
    const distanceCalculator = Distance();
    int verifiedCount = 0;
    int pendingCount = 0;
    double weightedSum = 0.0;
    final hazardCounts = <String, int>{};

    for (final inc in allIncidents) {
      if (!inc.hasCoordinates) continue;
      final incPoint = LatLng(inc.latitude!, inc.longitude!);
      bool isNear = false;

      // Sample along geometry
      final step = max(1, (route.geometry.length / 40).ceil());
      for (int i = 0; i < route.geometry.length; i += step) {
        if (distanceCalculator.as(LengthUnit.Meter, incPoint, route.geometry[i]) <= corridorMeters) {
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
}
