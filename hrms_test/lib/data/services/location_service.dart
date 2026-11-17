import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationPermissionDeniedException();
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionPermanentlyDeniedException();
    }

    if (permission == LocationPermission.unableToDetermine) {
      throw LocationPermissionUnavailableException();
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  Future<bool> isLocationEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  double distance(double lat, double lng, double officeLat, double officeLng) {
    return Geolocator.distanceBetween(lat, lng, officeLat, officeLng);
  }
}

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
