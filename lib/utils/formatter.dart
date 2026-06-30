/// Kumpulan helper untuk format tampilan angka & waktu.
/// Dipakai di Dashboard, Notification Panel, dan Summary Dialog
/// agar format konsisten di seluruh aplikasi.
class Formatter {
  Formatter._(); // Tidak perlu di-instantiate, semua method static.

  /// Format jarak dalam KM dengan 1 angka desimal.
  /// Contoh: 7.3, 12.0, 0.5
  static String km(double value) {
    return value.toStringAsFixed(1);
  }

  /// Format jarak dengan satuan "km" mengikuti.
  /// Contoh: "7.3 km", "12.0 km"
  static String kmWithUnit(double value) {
    return '${km(value)} km';
  }

  /// Format durasi dari Duration menjadi "HH:MM:SS".
  /// Contoh: Duration(seconds: 1457) → "00:24:17"
  static String duration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Format durasi singkat untuk rekap, contoh: "6j 14m"
  /// Dipakai di Dialog Summary FINISH SESI.
  static String durationShort(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0) {
      return '${hours}j ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Format jam saat ini untuk AppBar Dashboard.
  /// Contoh: "11:42 AM"
  static String timeOfDay(DateTime dt) {
    final hour24 = dt.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final period = hour24 < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }

  /// Format tanggal untuk AppBar Dashboard.
  /// Contoh: "Senin, 29 Jun"
  static String dateShort(DateTime dt) {
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, ${dt.day} $monthName';
  }

  /// Format label "Trip ke-N" untuk info bar Dashboard.
  /// Contoh: tripCount=3 → "Trip ke-4" (trip yang akan datang)
  static String tripLabel(int completedTripCount) {
    return 'Trip ke-${completedTripCount + 1}';
  }
}
