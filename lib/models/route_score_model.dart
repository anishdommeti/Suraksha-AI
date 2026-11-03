class RouteScoreModel {
  final String routeId;
  final double score; // 0 - 100
  final String scoreStatus; // "calculated", "insufficient_data"
  final String formulaVersion;
  final int verifiedIncidentCount;
  final int pendingReportCount;
  final String reportingPeriod;
  final double distanceKm;
  final int durationMinutes;
  final double exposureDensity;
  final String evidenceSummary;
  final String limitations;
  final String dataMode;
  final List<String> sourcesConsulted;
  final List<String> topHazards;

  RouteScoreModel({
    required this.routeId,
    required this.score,
    required this.scoreStatus,
    this.formulaVersion = 'v1.2-exposure-heuristic',
    required this.verifiedIncidentCount,
    required this.pendingReportCount,
    this.reportingPeriod = 'last_90_days',
    required this.distanceKm,
    required this.durationMinutes,
    required this.exposureDensity,
    required this.evidenceSummary,
    required this.limitations,
    required this.dataMode,
    this.sourcesConsulted = const [],
    this.topHazards = const [],
  });

  String get scoreCategory {
    if (score < 25.0) return 'Low Recorded Exposure';
    if (score < 55.0) return 'Moderate Recorded Exposure';
    if (score < 80.0) return 'Elevated Recorded Exposure';
    return 'High Recorded Exposure';
  }

  factory RouteScoreModel.fromJson(Map<String, dynamic> json) {
    return RouteScoreModel(
      routeId: json['route_id'] ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      scoreStatus: json['score_status'] ?? 'calculated',
      formulaVersion: json['formula_version'] ?? 'v1.2-exposure-heuristic',
      verifiedIncidentCount:
          (json['verified_incident_count'] as num?)?.toInt() ?? 0,
      pendingReportCount: (json['pending_report_count'] as num?)?.toInt() ?? 0,
      reportingPeriod: json['reporting_period'] ?? 'last_90_days',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      exposureDensity: (json['exposure_density'] as num?)?.toDouble() ?? 0.0,
      evidenceSummary: json['evidence_summary'] ?? '',
      limitations: json['limitations'] ?? '',
      dataMode: json['data_mode'] ?? 'SIMULATED_DEMO_DATA',
      sourcesConsulted:
          (json['sources_consulted'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_id': routeId,
      'score': score,
      'score_status': scoreStatus,
      'formula_version': formulaVersion,
      'verified_incident_count': verifiedIncidentCount,
      'pending_report_count': pendingReportCount,
      'reporting_period': reportingPeriod,
      'distance_km': distanceKm,
      'duration_minutes': durationMinutes,
      'exposure_density': exposureDensity,
      'evidence_summary': evidenceSummary,
      'limitations': limitations,
      'data_mode': dataMode,
      'sources_consulted': sourcesConsulted,
    };
  }
}
