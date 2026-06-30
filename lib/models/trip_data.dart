import 'app_state.dart';

/// Data class utama yang menyimpan seluruh metrik aplikasi.
/// Instance ini di-stream dari background service ke UI (Dashboard)
/// dan ke notification panel secara real-time.
class TripData {
  // ═══ STATE ═══
  final SessionState sessionState;
  final TripState tripState;

  // ═══ METRIK JARAK (dalam kilometer) ═══
  /// Jarak trip yang sedang aktif. Reset ke 0 setiap FINISH TRIP.
  final double kmTripAktif;

  /// Akumulasi jarak "kosongan" mencari orderan.
  /// Reset ke 0 hanya saat FINISH SESI.
  final double deadMileage;

  /// Total jarak mobil bergerak hari ini (trip + dead mileage).
  /// Reset ke 0 hanya saat FINISH SESI.
  final double totalKmHarian;

  // ═══ METADATA ═══
  /// Jumlah trip yang sudah selesai dalam sesi ini.
  final int tripCount;

  /// Waktu MULAI SESI ditekan. Null jika sesi belum dimulai.
  final DateTime? sessionStartTime;

  /// Waktu MULAI TRIP ditekan untuk trip aktif saat ini.
  /// Null jika tidak ada trip yang berjalan/dijeda.
  final DateTime? tripStartTime;

  /// Koordinat GPS terakhir yang tercatat (untuk kalkulasi delta jarak).
  final double? lastLatitude;
  final double? lastLongitude;

  const TripData({
    this.sessionState = SessionState.inactive,
    this.tripState = TripState.idle,
    this.kmTripAktif = 0.0,
    this.deadMileage = 0.0,
    this.totalKmHarian = 0.0,
    this.tripCount = 0,
    this.sessionStartTime,
    this.tripStartTime,
    this.lastLatitude,
    this.lastLongitude,
  });

  /// Membuat salinan TripData dengan beberapa field yang diubah.
  /// Pola ini dipakai terus-menerus oleh background service setiap
  /// kali ada update GPS atau perubahan state.
  TripData copyWith({
    SessionState? sessionState,
    TripState? tripState,
    double? kmTripAktif,
    double? deadMileage,
    double? totalKmHarian,
    int? tripCount,
    DateTime? sessionStartTime,
    DateTime? tripStartTime,
    double? lastLatitude,
    double? lastLongitude,
    bool clearSessionStartTime = false,
    bool clearTripStartTime = false,
  }) {
    return TripData(
      sessionState: sessionState ?? this.sessionState,
      tripState: tripState ?? this.tripState,
      kmTripAktif: kmTripAktif ?? this.kmTripAktif,
      deadMileage: deadMileage ?? this.deadMileage,
      totalKmHarian: totalKmHarian ?? this.totalKmHarian,
      tripCount: tripCount ?? this.tripCount,
      sessionStartTime: clearSessionStartTime
          ? null
          : (sessionStartTime ?? this.sessionStartTime),
      tripStartTime: clearTripStartTime
          ? null
          : (tripStartTime ?? this.tripStartTime),
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
    );
  }

  /// Reset total — dipanggil saat FINISH SESI.
  /// Semua metrik kembali 0, kembali ke SessionState.inactive.
  TripData resetSession() {
    return const TripData(
      sessionState: SessionState.inactive,
      tripState: TripState.idle,
    );
  }

  /// Reset KM/Trip saja — dipanggil saat FINISH TRIP.
  /// Dead Mileage & Total KM Harian TIDAK direset (sesuai keputusan Step 1).
  TripData resetTrip() {
    return copyWith(
      tripState: TripState.idle,
      kmTripAktif: 0.0,
      tripCount: tripCount + 1,
      clearTripStartTime: true,
    );
  }

  // ═══ SERIALISASI (untuk komunikasi antar isolate service ↔ UI) ═══
  Map<String, dynamic> toJson() {
    return {
      'sessionState': sessionState.index,
      'tripState': tripState.index,
      'kmTripAktif': kmTripAktif,
      'deadMileage': deadMileage,
      'totalKmHarian': totalKmHarian,
      'tripCount': tripCount,
      'sessionStartTime': sessionStartTime?.toIso8601String(),
      'tripStartTime': tripStartTime?.toIso8601String(),
      'lastLatitude': lastLatitude,
      'lastLongitude': lastLongitude,
    };
  }

  factory TripData.fromJson(Map<String, dynamic> json) {
    return TripData(
      sessionState: SessionState.values[json['sessionState'] as int? ?? 0],
      tripState: TripState.values[json['tripState'] as int? ?? 0],
      kmTripAktif: (json['kmTripAktif'] as num?)?.toDouble() ?? 0.0,
      deadMileage: (json['deadMileage'] as num?)?.toDouble() ?? 0.0,
      totalKmHarian: (json['totalKmHarian'] as num?)?.toDouble() ?? 0.0,
      tripCount: json['tripCount'] as int? ?? 0,
      sessionStartTime: json['sessionStartTime'] != null
          ? DateTime.parse(json['sessionStartTime'] as String)
          : null,
      tripStartTime: json['tripStartTime'] != null
          ? DateTime.parse(json['tripStartTime'] as String)
          : null,
      lastLatitude: (json['lastLatitude'] as num?)?.toDouble(),
      lastLongitude: (json['lastLongitude'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() {
    return 'TripData(session: ${sessionState.label}, trip: ${tripState.label}, '
        'kmTrip: $kmTripAktif, deadMileage: $deadMileage, total: $totalKmHarian)';
  }
}
