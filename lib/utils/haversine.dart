import 'dart:math' as math;

/// Kalkulasi jarak antara 2 titik koordinat GPS menggunakan
/// formula Haversine — akurat untuk jarak pendek-menengah
/// (cocok untuk tracking odometer kendaraan).
class Haversine {
  Haversine._(); // Tidak perlu di-instantiate, semua method static.

  /// Radius bumi rata-rata dalam kilometer.
  static const double _earthRadiusKm = 6371.0;

  /// Menghitung jarak antara 2 koordinat dalam KILOMETER.
  ///
  /// [lat1], [lon1] = koordinat titik awal
  /// [lat2], [lon2] = koordinat titik akhir
  static double distanceInKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double radLat1 = _degreesToRadians(lat1);
    final double radLat2 = _degreesToRadians(lat2);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(radLat1) *
            math.cos(radLat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Filter GPS noise: mengembalikan true jika delta jarak terlalu
  /// kecil untuk dianggap pergerakan nyata (driver berhenti/idle,
  /// bukan benar-benar bergerak). GPS modern punya margin error
  /// 3-5 meter bahkan saat diam.
  ///
  /// Threshold default 0.005 km (5 meter).
  static bool isNoise(double distanceKm, {double thresholdKm = 0.005}) {
    return distanceKm < thresholdKm;
  }

  /// Filter GPS jump: mengembalikan true jika delta jarak terlalu
  /// besar untuk waktu yang berlalu — indikasi GPS glitch/jump
  /// (misal sinyal memantul gedung tinggi), bukan pergerakan nyata.
  ///
  /// [distanceKm] = jarak yang dihitung
  /// [secondsElapsed] = waktu antara 2 titik GPS
  /// [maxSpeedKmh] = kecepatan maksimum wajar (default 180 km/jam,
  ///                 generous untuk highway tapi tetap filter glitch ekstrem)
  static bool isGpsJump({
    required double distanceKm,
    required int secondsElapsed,
    double maxSpeedKmh = 180.0,
  }) {
    if (secondsElapsed <= 0) return true;

    final double hoursElapsed = secondsElapsed / 3600.0;
    final double impliedSpeedKmh = distanceKm / hoursElapsed;

    return impliedSpeedKmh > maxSpeedKmh;
  }
}
