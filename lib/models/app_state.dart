/// State untuk SESI HARIAN (kontrol dari Dashboard).
/// Hanya berubah lewat tombol MULAI SESI / FINISH SESI.
enum SessionState {
  /// Sesi belum dimulai. Semua metrik = 0, GPS mati.
  inactive,

  /// Sesi sedang berjalan. GPS aktif, Dead Mileage bisa accumulate
  /// (saat tidak ada trip yang running).
  active,
}

/// State untuk TRIP PER ORDERAN (kontrol dari Notification Panel).
/// Hanya valid jika SessionState == active.
enum TripState {
  /// Sesi aktif tapi belum ada trip berjalan (menunggu orderan).
  /// Dead Mileage accumulate di state ini.
  idle,

  /// Trip sedang berjalan. KM/Trip accumulate, Dead Mileage berhenti.
  running,

  /// Trip dijeda. Semua metrik beku, GPS dijeda.
  paused,
}

/// Extension untuk label tampilan & helper logic SessionState.
extension SessionStateX on SessionState {
  bool get isActive => this == SessionState.active;

  String get label {
    switch (this) {
      case SessionState.inactive:
        return 'Sesi Belum Dimulai';
      case SessionState.active:
        return 'Sesi Berjalan';
    }
  }
}

/// Extension untuk label tampilan & helper logic TripState.
extension TripStateX on TripState {
  bool get isRunning => this == TripState.running;
  bool get isPaused => this == TripState.paused;
  bool get isIdle => this == TripState.idle;

  /// Dead Mileage hanya accumulate saat trip idle (menunggu orderan).
  bool get shouldAccumulateDeadMileage => this == TripState.idle;

  /// KM/Trip hanya accumulate saat trip sedang berjalan.
  bool get shouldAccumulateTripDistance => this == TripState.running;

  String get label {
    switch (this) {
      case TripState.idle:
        return 'Menunggu Orderan';
      case TripState.running:
        return 'Trip Berjalan';
      case TripState.paused:
        return 'Trip Dijeda';
    }
  }
}
