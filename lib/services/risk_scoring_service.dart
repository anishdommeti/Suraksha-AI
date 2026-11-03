import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/route_model.dart';
import '../models/route_score_model.dart';

class RiskScoringService {
  Future<RouteScoreModel> getRouteScore(RouteModel route) async {
    try {
      final url = Uri.parse(
        '${AppConfig.backendBaseUrl}/api/routes/${route.routeId}/score',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        return RouteScoreModel.fromJson(data);
      }
    } catch (_) {
      // Offline fallback
    }

    // Deterministic embedded fallback calculation
    if (route.routeId.contains('arterial')) {
      return RouteScoreModel(
        routeId: route.routeId,
        score: 18.4,
        scoreStatus: 'calculated',
        formulaVersion: 'v1.2-exposure-heuristic',
        verifiedIncidentCount: 1,
        pendingReportCount: 1,
        reportingPeriod: 'last_90_days',
        distanceKm: route.distanceKm,
        durationMinutes: route.durationMinutes,
        exposureDensity: 0.38,
        evidenceSummary: '1 verified incident (Road Obstruction) over 2.6 km. 1 community report pending verification.',
        limitations: 'Calculated using 200m spatial corridor. Does not guarantee personal safety.',
        dataMode: 'SIMULATED_DEMO_DATA',
      );
    } else if (route.routeId.contains('colony')) {
      return RouteScoreModel(
        routeId: route.routeId,
        score: 52.0,
        scoreStatus: 'calculated',
        formulaVersion: 'v1.2-exposure-heuristic',
        verifiedIncidentCount: 4,
        pendingReportCount: 0,
        reportingPeriod: 'last_90_days',
        distanceKm: route.distanceKm,
        durationMinutes: route.durationMinutes,
        exposureDensity: 1.90,
        evidenceSummary: '4 verified incidents (2 Poor Street Lighting, 1 Harassment Report, 1 Deserted Stretch).',
        limitations: 'High incident density along residential shortcut. Low score does not guarantee safety.',
        dataMode: 'SIMULATED_DEMO_DATA',
      );
    } else {
      return RouteScoreModel(
        routeId: route.routeId,
        score: 34.0,
        scoreStatus: 'calculated',
        formulaVersion: 'v1.2-exposure-heuristic',
        verifiedIncidentCount: 2,
        pendingReportCount: 1,
        reportingPeriod: 'last_90_days',
        distanceKm: route.distanceKm,
        durationMinutes: route.durationMinutes,
        exposureDensity: 0.97,
        evidenceSummary:
            '2 verified incidents along 3.1 km corridor in last 90 days.',
        limitations:
            'Corridor buffer 200m. Absence of reports is not proof of safety.',
        dataMode: 'SIMULATED_DEMO_DATA',
      );
    }
  }
}
