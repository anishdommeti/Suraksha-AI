import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationPermissionState {
  notRequested,
  locating,
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
  unavailable,
}

class LocationService extends ChangeNotifier {
  // Origin & Destination
  String _origin = 'Select Origin';
  String _destination = 'Saidabad Metro Station';
  LatLng? _originCoords;
  LatLng _destinationCoords = const LatLng(17.3753, 78.4908);
  bool _usingCurrentLocation = false;

  // Live Location State
  LocationPermissionState _permissionState =
      LocationPermissionState.notRequested;
  LatLng? _currentGpsCoords;
  double? _accuracyMeters;
  DateTime? _lastFixTime;
  String _statusMessage = 'Location not requested yet.';
  StreamSubscription<Position>? _positionStreamSub;

  String get origin => _origin;
  String get destination => _destination;
  LatLng get originCoords => _originCoords ?? const LatLng(17.3596, 78.5085);
  LatLng? get originCoordsNullable => _originCoords;
  bool get isOriginSet => _originCoords != null;
  LatLng get destinationCoords => _destinationCoords;
  bool get usingCurrentLocation => _usingCurrentLocation;

  LocationPermissionState get permissionState => _permissionState;
  LatLng? get currentGpsCoords => _currentGpsCoords;
  LatLng? get currentGpsPosition => _currentGpsCoords;
  double? get accuracyMeters => _accuracyMeters;
  DateTime? get lastFixTime => _lastFixTime;
  String get statusMessage => _statusMessage;
  String get gpsStatusDescription => _statusMessage;
  bool get hasValidGps =>
      _currentGpsCoords != null &&
      _permissionState == LocationPermissionState.granted;

  /// Helper to request and activate current GPS location as route origin
  Future<LatLng?> useCurrentLocation() async {
    await requestCurrentLocation(updateOrigin: true);
    return _currentGpsCoords;
  }

  LocationService() {
    // Note: Do NOT automatically trigger permission prompt on startup to respect user privacy.
  }

  /// Request permission and fetch actual device GPS coordinates
  Future<bool> requestCurrentLocation({bool updateOrigin = true}) async {
    _permissionState = LocationPermissionState.locating;
    _statusMessage = 'Checking device location services...';
    notifyListeners();

    try {
      // 1. Check if location services (GPS hardware) are enabled on the device
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _permissionState = LocationPermissionState.serviceDisabled;
        _statusMessage = 'Device GPS / location services are disabled. Please enable Location in Android Settings.';
        _usingCurrentLocation = false;
        notifyListeners();
        return false;
      }

      // 2. Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _permissionState = LocationPermissionState.denied;
          _statusMessage = 'Location permission was denied. You can select an origin manually or tap the map.';
          _usingCurrentLocation = false;
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _permissionState = LocationPermissionState.permanentlyDenied;
        _statusMessage = 'Location permission is permanently denied. Please enable it in Android App Settings.';
        _usingCurrentLocation = false;
        notifyListeners();
        return false;
      }

      // 3. Permission granted: fetch current device GPS fix with timeout
      _statusMessage = 'Acquiring satellite / network GPS fix...';
      notifyListeners();

      Position? position;
      try {
        // Try getting last known position first for instant responsiveness
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      // Get accurate fresh fix
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 7),
          ),
        );
      } catch (e) {
        // If high accuracy timed out but we had last known position, keep it
        if (position == null) {
          _permissionState = LocationPermissionState.unavailable;
          _statusMessage = 'GPS signal temporarily unavailable. Please select an origin manually.';
          _usingCurrentLocation = false;
          notifyListeners();
          return false;
        }
      }

      // 4. Update GPS coordinates with real data
      _currentGpsCoords = LatLng(position.latitude, position.longitude);
      _accuracyMeters = position.accuracy;
      _lastFixTime = position.timestamp;
      _permissionState = LocationPermissionState.granted;
      _statusMessage =
          'Live location active (±${position.accuracy.toStringAsFixed(0)}m accuracy)';

      if (updateOrigin) {
        _originCoords = _currentGpsCoords;
        _origin =
            'My Current Location (±${position.accuracy.toStringAsFixed(0)}m)';
        _usingCurrentLocation = true;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _permissionState = LocationPermissionState.unavailable;
      _statusMessage = 'Could not acquire GPS: $e';
      _usingCurrentLocation = false;
      notifyListeners();
      return false;
    }
  }

  /// Start live location tracking stream with sensible battery-friendly intervals
  void startLiveTracking() {
    if (_positionStreamSub != null) return;
    if (_permissionState != LocationPermissionState.granted) return;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Updates every 10 meters
    );

    _positionStreamSub =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          (Position pos) {
            _currentGpsCoords = LatLng(pos.latitude, pos.longitude);
            _accuracyMeters = pos.accuracy;
            _lastFixTime = pos.timestamp;

            // If user is currently using live location as route origin, update it dynamically
            if (_usingCurrentLocation) {
              _originCoords = _currentGpsCoords;
            }
            notifyListeners();
          },
          onError: (err) {
            _statusMessage = 'Live tracking error: $err';
            notifyListeners();
          },
        );
  }

  /// Stop live tracking to conserve battery
  void stopLiveTracking() {
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
  }

  void setOrigin(String val, [LatLng? coords]) {
    _origin = val;
    if (coords != null) {
      _originCoords = coords;
      _usingCurrentLocation = false;
    }
    notifyListeners();
  }

  void setDestination(String val, [LatLng? coords]) {
    _destination = val;
    if (coords != null) _destinationCoords = coords;
    notifyListeners();
  }

  void setLocations({
    required String origin,
    required String destination,
    required LatLng originCoords,
    required LatLng destinationCoords,
    bool usingCurrentLocation = false,
  }) {
    _origin = origin;
    _originCoords = originCoords;
    _destination = destination;
    _destinationCoords = destinationCoords;
    _usingCurrentLocation = usingCurrentLocation;
    notifyListeners();
  }

  void setManualOrigin(String name, LatLng coords) {
    _origin = name;
    _originCoords = coords;
    _usingCurrentLocation = false;
    notifyListeners();
  }

  void swapOriginDestination() {
    if (_originCoords == null) return;
    final tempName = _origin;
    final tempCoords = _originCoords!;
    _origin = _destination;
    _originCoords = _destinationCoords;
    _destination = tempName;
    _destinationCoords = tempCoords;
    _usingCurrentLocation = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopLiveTracking();
    super.dispose();
  }
}
