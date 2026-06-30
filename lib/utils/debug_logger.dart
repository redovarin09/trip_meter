import 'package:shared_preferences/shared_preferences.dart';

/// Logger debug yang menyimpan setiap langkah ke penyimpanan
/// PERSISTEN (bukan hanya memori). Jika app di-kill paksa oleh OS
/// di tengah proses, log sampai langkah terakhir tetap tersimpan
/// dan bisa dibaca begitu app dibuka kembali — solusi pengganti
/// ADB logcat saat wireless pairing tidak reliable.
class DebugLogger {
  DebugLogger._();

  static const String _key = 'debug_log_session';

  /// Tambah satu baris log. Dipanggil synchronous-style (fire and
  /// forget) tapi SharedPreferences menulis ke disk segera di balik
  /// layar, jauh lebih cepat dari kemungkinan app di-kill OS.
  static Future<void> log(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? [];
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    existing.add('[$timestamp] $message');
    await prefs.setStringList(_key, existing);
  }

  /// Ambil semua log dari sesi terakhir (termasuk sesi yang
  /// kemungkinan berakhir karena app di-kill paksa).
  static Future<List<String>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  /// Bersihkan log — panggil saat mulai sesi debug baru supaya
  /// tidak campur dengan log percobaan sebelumnya.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
