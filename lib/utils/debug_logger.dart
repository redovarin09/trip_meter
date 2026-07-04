import 'dart:io';

/// Logger debug yang menyimpan setiap langkah ke penyimpanan
/// PERSISTEN (bukan hanya memori), memakai dart:io File murni --
/// TIDAK memakai SharedPreferences karena plugin method channel
/// terbukti hang/tidak pernah direspons di isolate headless milik
/// flutter_background_service. File I/O adalah operasi VM murni,
/// tidak lewat platform channel, sehingga reliable di isolate manapun.
class DebugLogger {
  DebugLogger._();

  static const String _fileName =
      '/data/data/com.tripmeter.trip_meter/app_flutter/debug_log.txt';

  static File get _file => File(_fileName);

  /// Tambah satu baris log. Sepenuhnya synchronous di level OS
  /// (writeAsStringSync dengan mode append) -- tidak ada await
  /// yang bisa menggantung.
  static Future<void> log(String message) async {
    try {
      final timestamp = DateTime.now().toIso8601String().substring(11, 23);
      _file.writeAsStringSync(
        '[$timestamp] $message\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // sengaja diam -- logger tidak boleh menyebabkan crash aplikasi
    }
  }

  /// Ambil semua log dari sesi terakhir (termasuk sesi yang
  /// kemungkinan berakhir karena app di-kill paksa).
  static Future<List<String>> getLogs() async {
    try {
      if (!_file.existsSync()) return [];
      final content = _file.readAsStringSync();
      return content
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Bersihkan log -- panggil saat mulai sesi debug baru supaya
  /// tidak campur dengan log percobaan sebelumnya.
  static Future<void> clear() async {
    try {
      if (_file.existsSync()) {
        _file.deleteSync();
      }
    } catch (_) {
      // sengaja diam
    }
  }
}
