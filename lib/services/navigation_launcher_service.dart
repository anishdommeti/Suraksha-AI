import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';

/// NavigationLauncherService
/// Handles seamless handoff of planned routes from SURAKSHA AI to Google Maps
/// for turn-by-turn navigation via native Android deep links and web fallback.
class NavigationLauncherService {
  /// Opens Google Maps with prefilled origin and destination.
  ///
  /// Note on OSRM vs Google Maps:
  /// Google Maps turn-by-turn navigation dynamically calculates its own real-time
  /// traffic-optimized route between the supplied origin and destination.
  /// SURAKSHA AI preserves your analyzed OSRM route and transparently hands off
  /// the journey endpoints to Google Maps.
  static Future<bool> launchGoogleMapsNavigation({
    required BuildContext context,
    required LatLng destination,
    LatLng? origin,
    bool isOriginCurrentLocation = false,
    String? destinationName,
    String? originName,
  }) async {
    // 1. Validate destination coordinates
    if (destination.latitude == 0 && destination.longitude == 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid destination. Please select a valid point on the map.',
            ),
            backgroundColor: Color(0xFFC62828),
          ),
        );
      }
      return false;
    }

    final double destLat = destination.latitude;
    final double destLng = destination.longitude;

    // 2. Build Universal Google Maps Directions URL
    // Format: https://www.google.com/maps/dir/?api=1&destination=LAT,LNG&travelmode=driving
    final String urlString;
    if (origin != null && !isOriginCurrentLocation) {
      final double origLat = origin.latitude;
      final double origLng = origin.longitude;
      urlString =
          'https://www.google.com/maps/dir/?api=1&origin=$origLat,$origLng&destination=$destLat,$destLng&travelmode=driving';
    } else {
      // If current GPS or no specific manual origin, Google Maps defaults to device current GPS
      urlString =
          'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving';
    }
    final Uri directionsWebUri = Uri.parse(urlString);

    // 3. Build Native Android Google Navigation Intent URL
    final Uri nativeNavUri = Uri.parse(
      'google.navigation:q=$destLat,$destLng&mode=d',
    );

    try {
      // Attempt 1: Native Google Maps Turn-by-Turn Navigation Intent
      if (await canLaunchUrl(nativeNavUri)) {
        final launched = await launchUrl(
          nativeNavUri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
        if (launched) return true;
      }

      // Attempt 2: Universal Google Maps Directions in external app
      if (await canLaunchUrl(directionsWebUri)) {
        final launched = await launchUrl(
          directionsWebUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      }

      // Attempt 3: In-app / Browser fallback
      final fallbackLaunched = await launchUrl(
        directionsWebUri,
        mode: LaunchMode.platformDefault,
      );
      if (fallbackLaunched) return true;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open Google Maps navigation. Please verify Google Maps or a browser is available.',
            ),
            backgroundColor: Color(0xFFE65100),
          ),
        );
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation handoff error: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
      return false;
    }
  }
}
