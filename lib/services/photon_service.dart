import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
import '../models/photon_feature.dart';

class PhotonService {
  // In-memory cache for recent search queries to avoid repeated network calls
  final Map<String, List<PhotonFeature>> _queryCache = {};

  // Maximum cached queries to maintain low memory profile
  static const int _maxCacheSize = 50;

  // Curated offline Hyderabad landmarks fallback when device has no connectivity
  static final List<PhotonFeature> _hyderabadLandmarks = [
    PhotonFeature(
      name: 'Charminar',
      street: 'Charminar Rd',
      city: 'Hyderabad',
      state: 'Telangana',
      coordinates: LatLng(17.3616, 78.4747),
    ),
    PhotonFeature(
      name: 'Matrusri Engineering College',
      street: 'Saidabad Main Rd',
      city: 'Hyderabad',
      state: 'Telangana',
      coordinates: LatLng(17.3596, 78.5085),
    ),
    PhotonFeature(
      name: 'Saidabad Metro Station',
      street: 'Chanchalguda - Saidabad Corridor',
      city: 'Hyderabad',
      state: 'Telangana',
      coordinates: LatLng(17.3753, 78.4908),
    ),
    PhotonFeature(
      name: 'Malakpet Metro Station',
      street: 'Mahbubnagar Rd',
      city: 'Hyderabad',
      state: 'Telangana',
      coordinates: LatLng(17.3765, 78.4915),
    ),
    PhotonFeature(
      name: 'HITEC City Cyber Towers',
      street: 'Hitec City Main Rd',
      city: 'Hyderabad',
      state: 'Telangana',
      coordinates: LatLng(17.4504, 78.3808),
    ),
    PhotonFeature(
      name: 'Secunderabad Railway Station',
      street: 'Station Rd',
      city: 'Secunderabad',
      state: 'Telangana',
      coordinates: LatLng(17.4344, 78.5017),
    ),
    PhotonFeature(
      name: 'Osmania General Hospital',
      street: 'Afzal Gunj',
      city: 'Hyderabad',
      state: 'Telangana',
      coordinates: LatLng(17.3732, 78.4776),
    ),
    PhotonFeature(
      name: 'Gachibowli Stadium',
      street: 'Old Mumbai Highway',
      city: 'Hyderabad',
      state: 'Telangana',
      coordinates: LatLng(17.4435, 78.3489),
    ),
  ];

  Future<List<PhotonFeature>> search(String query, {int limit = 6}) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    // Check cache
    if (_queryCache.containsKey(cleanQuery)) {
      return _queryCache[cleanQuery]!;
    }

    try {
      final uri = Uri.parse(
        '${AppConfig.photonBaseUrl}?q=${Uri.encodeComponent(query)}'
        '&lat=${AppConfig.defaultLat}&lon=${AppConfig.defaultLng}&limit=$limit',
      );

      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': AppConfig.osmUserAgent,
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final features = data['features'] as List<dynamic>? ?? [];

        final results = features
            .map((f) => PhotonFeature.fromJson(f as Map<String, dynamic>))
            .toList();

        // Save to cache
        if (_queryCache.length >= _maxCacheSize) {
          _queryCache.remove(_queryCache.keys.first);
        }
        _queryCache[cleanQuery] = results;

        return results;
      }
    } catch (_) {
      // Offline fallback: check local curated Hyderabad landmarks without fabricating random results
      final matchingLandmarks = _hyderabadLandmarks.where((f) {
        return f.name.toLowerCase().contains(cleanQuery) ||
            (f.street?.toLowerCase().contains(cleanQuery) ?? false) ||
            (f.city?.toLowerCase().contains(cleanQuery) ?? false);
      }).toList();

      if (matchingLandmarks.isNotEmpty) {
        return matchingLandmarks;
      }
    }

    return [];
  }

  void clearCache() {
    _queryCache.clear();
  }
}
