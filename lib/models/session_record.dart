/// Satu baris riwayat sesi kerja yang sudah selesai (FINISH SESI).
/// Disimpan sebagai JSON-line di HistoryService -- immutable,
/// dibuat sekali saat sesi selesai, tidak pernah diubah lagi.
class SessionRecord {
  /// Waktu sesi dimulai (MULAI SESI ditekan).
  final DateTime sessionStartTime;

  /// Waktu sesi selesai (FINISH SESI ditekan) -- dipakai sebagai
  /// timestamp utama untuk pengurutan & filter tanggal di Riwayat.
  final DateTime sessionEndTime;

  /// Total KM harian (termasuk dead mileage) saat sesi berakhir.
  final double totalKmHarian;

  /// Total dead mileage (KM kosongan tanpa penumpang) saat sesi berakhir.
  final double deadMileage;

  /// Jumlah trip yang berhasil diselesaikan dalam sesi ini.
  final int tripCount;

  const SessionRecord({
    required this.sessionStartTime,
    required this.sessionEndTime,
    required this.totalKmHarian,
    required this.deadMileage,
    required this.tripCount,
  });

  /// Durasi sesi kerja, dari mulai sampai selesai.
  Duration get duration => sessionEndTime.difference(sessionStartTime);

  /// KM efektif (ada penumpang) = total dikurangi dead mileage.
  double get effectiveKm => totalKmHarian - deadMileage;

  /// Persentase efisiensi (KM efektif / total KM), 0-100.
  /// Berguna untuk insight driver: makin tinggi makin efisien.
  double get efficiencyPercent {
    if (totalKmHarian <= 0) return 0;
    return (effectiveKm / totalKmHarian) * 100;
  }

  Map<String, dynamic> toJson() => {
        'sessionStartTime': sessionStartTime.toIso8601String(),
        'sessionEndTime': sessionEndTime.toIso8601String(),
        'totalKmHarian': totalKmHarian,
        'deadMileage': deadMileage,
        'tripCount': tripCount,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      sessionStartTime: DateTime.parse(json['sessionStartTime'] as String),
      sessionEndTime: DateTime.parse(json['sessionEndTime'] as String),
      totalKmHarian: (json['totalKmHarian'] as num).toDouble(),
      deadMileage: (json['deadMileage'] as num).toDouble(),
      tripCount: json['tripCount'] as int,
    );
  }
}
