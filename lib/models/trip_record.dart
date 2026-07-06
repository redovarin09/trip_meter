/// Satu baris riwayat trip individual di dalam sebuah sesi kerja.
/// Dicatat setiap kali FINISH TRIP ditekan, disimpan sementara di
/// isolate service, lalu ikut tersimpan penuh ke SessionRecord saat
/// FINISH SESI.
class TripRecord {
  /// Waktu trip dimulai (MULAI TRIP ditekan).
  final DateTime tripStartTime;

  /// Waktu trip selesai (FINISH TRIP ditekan).
  final DateTime tripEndTime;

  /// Jarak yang ditempuh selama trip ini (km).
  final double kmTrip;

  const TripRecord({
    required this.tripStartTime,
    required this.tripEndTime,
    required this.kmTrip,
  });

  /// Durasi trip, dari mulai sampai selesai.
  Duration get duration => tripEndTime.difference(tripStartTime);

  Map<String, dynamic> toJson() => {
        'tripStartTime': tripStartTime.toIso8601String(),
        'tripEndTime': tripEndTime.toIso8601String(),
        'kmTrip': kmTrip,
      };

  factory TripRecord.fromJson(Map<String, dynamic> json) {
    return TripRecord(
      tripStartTime: DateTime.parse(json['tripStartTime'] as String),
      tripEndTime: DateTime.parse(json['tripEndTime'] as String),
      kmTrip: (json['kmTrip'] as num).toDouble(),
    );
  }
}
