import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suraksha_ai/models/incident_model.dart';
import 'package:suraksha_ai/models/facility_model.dart';
import 'package:suraksha_ai/models/route_score_model.dart';
import 'package:suraksha_ai/models/photon_feature.dart';
import 'package:suraksha_ai/models/saved_location_model.dart';
import 'package:suraksha_ai/models/chat_message_model.dart';
import 'package:suraksha_ai/services/saved_locations_service.dart';
import 'package:suraksha_ai/services/theme_service.dart';
import 'package:suraksha_ai/services/location_service.dart';

void main() {
  group('SURAKSHA AI Incident & Reporting Tests', () {
    test('IncidentModel parses official verified incident correctly', () {
      final json = {
        'incident_id': 'HYD-2024-ACC-01',
        'category': 'ROAD_ACCIDENT',
        'severity': 'HIGH',
        'latitude': 17.3621,
        'longitude': 78.5085,
        'occurred_at': '2024-03-12T20:30:00Z',
        'reported_at': '2024-03-12T21:00:00Z',
        'description': 'Head-on collision at Saidabad Crossroads',
        'source_type': 'OFFICIAL_SOURCE',
        'source_name': 'Hyderabad Traffic Police Annual Report 2024',
        'verification_status': 'OFFICIAL_SOURCE',
        'is_simulated': false,
        'location_precision': 'EXACT',
      };

      final incident = IncidentModel.fromJson(json);

      expect(incident.id, 'HYD-2024-ACC-01');
      expect(incident.category, 'ROAD_ACCIDENT');
      expect(incident.isOfficialSource, isTrue);
      expect(incident.isVerified, isTrue);
      expect(incident.isSimulated, isFalse);
      expect(incident.locationPrecision, 'EXACT');
      expect(incident.formattedCategory, 'ROAD ACCIDENT');
    });

    test(
      'IncidentModel handles community pending report and lifecycle flags',
      () {
        final json = {
          'incident_id': 'COMM-2024-001',
          'category': 'POOR_STREET_LIGHTING',
          'severity': 'MEDIUM',
          'latitude': 17.3630,
          'longitude': 78.5040,
          'occurred_at': '2024-04-01T19:00:00Z',
          'reported_at': '2024-04-01T19:15:00Z',
          'description': 'Dark corridor near Singareni colony park',
          'source_type': 'COMMUNITY_REPORT',
          'source_name': 'SURAKSHA Community',
          'verification_status': 'PENDING',
          'is_simulated': false,
          'location_precision': 'APPROXIMATE',
        };

        final incident = IncidentModel.fromJson(json);

        expect(incident.id, 'COMM-2024-001');
        expect(incident.isPending, isTrue);
        expect(incident.isVerified, isFalse);
        expect(incident.locationPrecision, 'APPROXIMATE');
        expect(incident.hasCoordinates, isTrue);
      },
    );

    test('PublicFacilityModel parses public safety infrastructure', () {
      final json = {
        'facility_id': 'FAC-PS-01',
        'name': 'Saidabad Police Station',
        'facility_type': 'POLICE_STATION',
        'latitude': 17.3615,
        'longitude': 78.5092,
        'jurisdiction': 'Saidabad, Hyderabad East',
        'contact_phone': '040-27854770',
        'source_name': 'Hyderabad City Police Directory',
      };

      final facility = PublicFacilityModel.fromJson(json);

      expect(facility.facilityId, 'FAC-PS-01');
      expect(facility.name, 'Saidabad Police Station');
      expect(facility.facilityType, 'POLICE_STATION');
      expect(facility.contactPhone, '040-27854770');
    });

    test('RouteScoreModel parses sourcesConsulted and exposure heuristic', () {
      final json = {
        'route_id': 'route_arterial_saidabad',
        'score': 24.5,
        'score_status': 'calculated',
        'formula_version': 'v2.0-precision-aware-exposure',
        'verified_incident_count': 2,
        'pending_report_count': 0,
        'distance_km': 1.6,
        'duration_minutes': 8,
        'exposure_density': 0.66,
        'evidence_summary': 'Low exposure corridor with 2 verified incidents.',
        'limitations': 'Reflects recorded reports only.',
        'data_mode': 'HYBRID_OFFICIAL_AND_COMMUNITY',
        'sources_consulted': [
          'Hyderabad Traffic Police Annual Report 2024',
          'Telangana SHE Teams Annual Performance Report',
        ],
      };

      final score = RouteScoreModel.fromJson(json);

      expect(score.routeId, 'route_arterial_saidabad');
      expect(score.score, 24.5);
      expect(score.scoreCategory, 'Low Recorded Exposure');
      expect(score.verifiedIncidentCount, 2);
      expect(score.sourcesConsulted.length, 2);
      expect(
        score.sourcesConsulted.first,
        contains('Hyderabad Traffic Police'),
      );
    });

    test('PhotonFeature parses GeoJSON properties and coordinates', () {
      final json = {
        'geometry': {
          'coordinates': [78.4747, 17.3616], // [lon, lat]
          'type': 'Point',
        },
        'properties': {
          'name': 'Charminar',
          'street': 'Charminar Road',
          'city': 'Hyderabad',
          'state': 'Telangana',
          'country': 'India',
          'osm_type': 'N',
          'osm_id': 123456,
        },
      };

      final feature = PhotonFeature.fromJson(json);

      expect(feature.name, 'Charminar');
      expect(feature.coordinates.latitude, 17.3616);
      expect(feature.coordinates.longitude, 78.4747);
      expect(feature.displayName, contains('Charminar'));
      expect(feature.displayName, contains('Hyderabad'));
    });

    test('SavedLocationsService manages saved places', () {
      final service = SavedLocationsService();
      expect(service.locations.length, greaterThanOrEqualTo(3));

      final testLoc = SavedLocationModel(
        id: 'test_gym',
        name: 'Fitness Gym',
        address: 'Saidabad, Hyderabad',
        coordinates: LatLng(17.3650, 78.5050),
        iconType: 'favorite',
      );

      service.addLocation(testLoc);
      expect(service.locations.any((l) => l.id == 'test_gym'), isTrue);

      service.removeLocation('test_gym');
      expect(service.locations.any((l) => l.id == 'test_gym'), isFalse);
    });

    test('ThemeService manages Light, Dark, and System ThemeModes', () async {
      SharedPreferences.setMockInitialValues({'suraksha_theme_mode': 'dark'});
      final themeService = ThemeService();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(themeService.themeMode, ThemeMode.dark);
      expect(themeService.isDarkMode, isTrue);

      await themeService.setThemeMode(ThemeMode.light);
      expect(themeService.themeMode, ThemeMode.light);
      expect(themeService.isDarkMode, isFalse);

      await themeService.setThemeMode(ThemeMode.system);
      expect(themeService.themeMode, ThemeMode.system);
    });

    test('LocationService initializes safely and tracks GPS state', () {
      final loc = LocationService();
      expect(loc.permissionState, LocationPermissionState.notRequested);
      expect(loc.hasValidGps, isFalse);
      expect(loc.originCoords, isNotNull);
      expect(loc.destinationCoords, isNotNull);

      loc.setManualOrigin('Test Origin', const LatLng(17.4000, 78.4500));
      expect(loc.origin, 'Test Origin');
      expect(loc.originCoords.latitude, 17.4000);
      expect(loc.usingCurrentLocation, isFalse);
    });

    test('RouteComparisonCardData parses structured assistant response', () {
      final json = {
        'route_id': 'route_arterial_saidabad',
        'name': 'Route A: Main Arterial (Saidabad Main Rd)',
        'distance_km': 2.6,
        'duration_minutes': 9,
        'score': 18.4,
        'score_category': 'LOW',
        'verified_count': 1,
        'official_count': 1,
        'pending_count': 0,
        'top_hazards': ['Road Accident'],
        'is_recommended': true,
        'recommendation_reason':
            'Lower recorded incident exposure along major corridor',
      };

      final card = RouteComparisonCardData.fromJson(json);

      expect(card.routeId, 'route_arterial_saidabad');
      expect(card.name, contains('Route A'));
      expect(card.distanceKm, 2.6);
      expect(card.durationMinutes, 9);
      expect(card.score, 18.4);
      expect(card.scoreCategory, 'LOW');
      expect(card.isRecommended, isTrue);
      expect(card.verifiedCount, 1);
      expect(card.topHazards, contains('Road Accident'));
    });
  });
}
