import 'dart:async';

import 'package:geolocator/geolocator.dart' as geo;

class LocationService {
  Future<geo.Position> currentPosition() async {
    final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    var permission = await geo.Geolocator.checkPermission();

    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }

    if (permission == geo.LocationPermission.denied) {
      throw LocationPermissionDeniedException();
    }

    if (permission == geo.LocationPermission.deniedForever) {
      throw LocationPermissionPermanentlyDeniedException();
    }

    if (permission == geo.LocationPermission.unableToDetermine) {
      throw LocationPermissionUnavailableException();
    }

    try {
      return await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on TimeoutException {
      throw LocationTimeoutException();
    } on geo.LocationServiceDisabledException {
      throw LocationServiceDisabledException();
    } catch (e) {
      throw LocationFetchException(e.toString());
    }
  }

  Future<bool> openAppSettings() {
    return geo.Geolocator.openAppSettings();
  }

  Future<bool> openLocationSettings() {
    return geo.Geolocator.openLocationSettings();
  }

  Future<bool> isLocationEnabled() {
    return geo.Geolocator.isLocationServiceEnabled();
  }

  Future<geo.LocationPermission> checkPermission() {
    return geo.Geolocator.checkPermission();
  }

  double distance(double lat, double lng, double officeLat, double officeLng) {
    return geo.Geolocator.distanceBetween(lat, lng, officeLat, officeLng);
  }
}

// Custom exceptions

class LocationServiceDisabledException implements Exception {
  @override
  String toString() => 'Location services are disabled.';
}

class LocationPermissionDeniedException implements Exception {
  @override
  String toString() => 'Location permission was denied.';
}

class LocationPermissionPermanentlyDeniedException implements Exception {
  @override
  String toString() => 'Location permission is permanently denied.';
}

class LocationPermissionUnavailableException implements Exception {
  @override
  String toString() => 'Location permission is unavailable.';
}

class LocationTimeoutException implements Exception {
  @override
  String toString() => 'Unable to get location. Please try again.';
}

class LocationFetchException implements Exception {
  final String message;

  LocationFetchException(this.message);

  @override
  String toString() => 'Unable to fetch location: $message';
}
