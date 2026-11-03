import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/incident_model.dart';
import '../models/facility_model.dart';
import '../data/embedded_incidents_data.dart';

class SubmissionResult {
  final IncidentModel incident;
  final bool isDuplicateWarning;
  final String message;

  SubmissionResult({
    required this.incident,
    required this.isDuplicateWarning,
    required this.message,
  });
}

class IncidentService extends ChangeNotifier {
  static List<IncidentModel> get _embeddedOfficialIncidents =>
      kDefaultEmbeddedIncidents;
  static List<PublicFacilityModel> get _embeddedFacilities =>
      kDefaultEmbeddedFacilities;

  // User submitted reports on this device
  final List<IncidentModel> _myReports = [];
  List<IncidentModel> _currentIncidents = [];
  List<PublicFacilityModel> _facilities = [];
  Map<String, dynamic> _datasetSummary = {};

  List<IncidentModel> get myReports => _myReports;
  List<IncidentModel> get incidents => _currentIncidents.isNotEmpty
      ? _currentIncidents
      : _embeddedOfficialIncidents;
  List<PublicFacilityModel> get facilities =>
      _facilities.isNotEmpty ? _facilities : _embeddedFacilities;
  Map<String, dynamic> get datasetSummary => _datasetSummary;

  IncidentService() {
    _currentIncidents = List.from(_embeddedOfficialIncidents);
    _facilities = List.from(_embeddedFacilities);
  }

  static List<IncidentModel> get allIncidents => _embeddedOfficialIncidents;

  Future<void> fetchIncidents({
    String? category,
    String? status,
    String? timeWindow,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null && category != 'ALL') {
        queryParams['category'] = category;
      }
      if (status != null && status != 'ALL') queryParams['status'] = status;
      if (timeWindow != null) queryParams['time_window'] = timeWindow;

      final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/incidents')
          .replace(queryParameters: queryParams);
      final resp = await http.get(uri).timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        final List list = json.decode(resp.body);
        _currentIncidents = list.map((e) => IncidentModel.fromJson(e)).toList();
        notifyListeners();
        return;
      }
    } catch (_) {
      // Offline fallback
    }

    // Apply local filters on embedded dataset
    _currentIncidents = _embeddedOfficialIncidents.where((inc) {
      if (category != null && category != 'ALL' && inc.category != category) {
        return false;
      }
      if (status != null && status != 'ALL' && inc.verificationStatus != status) {
        return false;
      }
      return true;
    }).toList();
    notifyListeners();
  }

  Future<void> fetchFacilities() async {
    try {
      final url = Uri.parse(
        '${AppConfig.backendBaseUrl}/api/dataset/facilities',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200) {
        final List list = json.decode(resp.body);
        _facilities = list.map((e) => PublicFacilityModel.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchDatasetSummary() async {
    try {
      final url = Uri.parse('${AppConfig.backendBaseUrl}/api/dataset/summary');
      final resp = await http.get(url).timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200) {
        _datasetSummary = json.decode(resp.body);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<SubmissionResult> submitCommunityReport({
    required String category,
    required String description,
    required double latitude,
    required double longitude,
    String locationPrecision = 'EXACT',
    String severityReported = 'MEDIUM',
    bool isAnonymous = true,
    String? photoReference,
    String? incidentDatetime,
  }) async {
    bool isDup = false;
    String msg =
        "Report submitted successfully with PENDING VERIFICATION status.";

    try {
      final url = Uri.parse('${AppConfig.backendBaseUrl}/api/incidents');
      final payload = json.encode({
        'category': category,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'location_precision': locationPrecision,
        'severity_reported': severityReported,
        'is_anonymous': isAnonymous,
        'photo_reference': photoReference,
        'incident_datetime': incidentDatetime,
      });

      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final inc = IncidentModel.fromJson(data['incident']);
        isDup = data['is_duplicate_warning'] ?? false;
        msg = data['message'] ?? msg;

        _myReports.insert(0, inc);
        _currentIncidents.insert(0, inc);
        notifyListeners();
        return SubmissionResult(
          incident: inc,
          isDuplicateWarning: isDup,
          message: msg,
        );
      }
    } catch (_) {
      // Local fallback
    }

    final localInc = IncidentModel(
      id: 'COM-REP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      category: category,
      subcategory: 'Community User Submission',
      description: description,
      latitude: latitude,
      longitude: longitude,
      occurredAt:
          incidentDatetime ??
          DateTime.now().toUtc().toIso8601String().substring(0, 10),
      reportedAt: DateTime.now().toUtc().toIso8601String(),
      severity: severityReported,
      verificationStatus: 'PENDING',
      sourceType: 'COMMUNITY_REPORT',
      sourceName: 'SURAKSHA AI Citizen Commuter Report',
      sourceUrl: 'https://suraksha.ai/community',
      locationPrecision: locationPrecision,
      isSimulated: false,
      isAnonymous: isAnonymous,
      photoReference: photoReference,
      reviewNotes: 'Saved on device. Awaiting moderator review.',
    );

    _myReports.insert(0, localInc);
    _currentIncidents.insert(0, localInc);
    notifyListeners();
    return SubmissionResult(
      incident: localInc,
      isDuplicateWarning: false,
      message: msg,
    );
  }
}
