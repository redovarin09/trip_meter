import 'dart:convert';
import 'dart:io';

import '../models/session_record.dart';

/// Menyimpan riwayat sesi kerja yang sudah selesai, format JSON-lines
/// (satu record per baris) di dart:io File murni -- BUKAN
/// SharedPreferences, karena append() dipanggil dari isolate service
/// (_onServiceStart) saat finishSession, dan SharedPreferences
/// terbukti hang total di isolate headless (lihat riwayat debugging
/// DebugLogger). Pola ini identik dengan DebugLogger yang sudah
/// terbukti reliable di isolate manapun.
class HistoryService {
  HistoryService._();

  static const String _fileName =
      '/data/data/com.tripmeter.trip_meter/app_flutter/session_history.jsonl';

  static File get _file => File(_fileName);

  /// Tambah satu record riwayat sesi. Dipanggil sekali setiap
  /// FINISH SESI, dari isolate service.
  static Future<void> append(SessionRecord record) async {
    try {
      final line = jsonEncode(record.toJson());
      _file.writeAsStringSync(
        '$line\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // sengaja diam -- history tidak boleh menyebabkan crash aplikasi
    }
  }

  /// Ambil semua riwayat sesi, terbaru dulu (descending berdasarkan
  /// sessionEndTime). Dipanggil dari isolate UI (halaman Riwayat).
  static Future<List<SessionRecord>> getAll() async {
    try {
      if (!_file.existsSync()) return [];
      final lines = _file
          .readAsStringSync()
          .split('\n')
          .where((line) => line.trim().isNotEmpty);

      final records = <SessionRecord>[];
      for (final line in lines) {
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          records.add(SessionRecord.fromJson(json));
        } catch (_) {
          // lewati baris yang corrupt/tidak valid, jangan gagalkan semua
        }
      }

      records.sort((a, b) => b.sessionEndTime.compareTo(a.sessionEndTime));
      return records;
    } catch (_) {
      return [];
    }
  }

  /// Hapus seluruh riwayat. Dipanggil dari halaman Pengaturan.
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
