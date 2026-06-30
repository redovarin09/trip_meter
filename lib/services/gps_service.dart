import 'package:geolocator/geolocator.dart';
import '../utils/haversine.dart';

/// Hasil pemrosesan satu update GPS: delta jarak yang sudah
/// lolos filter noise/glitch, siap ditambahkan ke metrik.
class GpsDelta {
  final double distanceKm;
  final double latitude;
  final double longitude;

  const GpsDelta({
    required this.distanceKm,
    required this.latitude,
    required this.longitude,
  });
}

/// Service yang membungkus package geolocator: handle permission,
/// stream posisi real-time, dan hitung delta jarak yang sudah
/// difilter dari noise GPS & glitch lonjakan sinyal.
class GpsService {
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // update setiap pergerakan >= 5 meter
  );

  /// Memastikan semua permission lokasi dasar (foreground) sudah
  /// diberikan. Return true jika siap tracking.
  ///
  /// Catatan: izin "always" (background location, Android 10+)
  /// ditangani terpisah di utils/permission_handler.dart karena
  /// alurnya 2 tahap (minta foreground dulu, baru background) —
  /// tidak bisa diminta sekaligus di satu dialog.
  static Future<bool> ensurePermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Stream posisi GPS real-time. Setiap event adalah titik baru
  /// yang sudah lolos distanceFilter bawaan geolocator (>= 5 meter).
  static Stream<Position> get positionStream {
    return Geolocator.getPositionStream(locationSettings: _locationSettings);
  }

  /// Menghitung delta jarak antara posisi sebelumnya dan posisi baru.
  ///
  /// Return null jika delta TIDAK VALID (noise/glitch) — artinya
  /// pemanggil (background_service.dart) tidak boleh menambahkan
  /// apapun ke metrik untuk update GPS ini.
  static GpsDelta? calculateDelta({
    required double prevLat,
    required double prevLon,
    required DateTime prevTimestamp,
    required Position newPosition,
  }) {
    final distanceKm = Haversine.distanceInKm(
      lat1: prevLat,
      lon1: prevLon,
      lat2: newPosition.latitude,
      lon2: newPosition.longitude,
    );

    if (Haversine.isNoise(distanceKm)) {
      return null;
    }

    final secondsElapsed =
        newPosition.timestamp.difference(prevTimestamp).inSeconds;

    if (Haversine.isGpsJump(
      distanceKm: distanceKm,
      secondsElapsed: secondsElapsed,
    )) {
      return null;
    }

    return GpsDelta(
      distanceKm: distanceKm,
      latitude: newPosition.latitude,
      longitude: newPosition.longitude,
    );
  }
}
