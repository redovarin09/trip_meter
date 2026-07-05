import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'history_service.dart';

/// Backup: share file mentah session_history.jsonl (format sama
/// persis dengan yang dibaca HistoryService -- portable).
/// Restore: pilih file .jsonl via file picker, replace isi riwayat.
class BackupRestoreService {
  BackupRestoreService._();

  static const String _historyFileName =
      '/data/data/com.tripmeter.trip_meter/app_flutter/session_history.jsonl';

  /// Share file riwayat mentah untuk backup manual (WhatsApp, Drive, dst).
  /// Melempar exception kalau tidak ada riwayat atau gagal share.
  static Future<void> backup() async {
    final file = File(_historyFileName);
    if (!file.existsSync() || file.lengthSync() == 0) {
      throw Exception('Belum ada riwayat untuk di-backup.');
    }

    // Copy ke temporary directory dengan nama yang jelas, supaya
    // tidak langsung share file asli aplikasi (best practice share_plus).
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final backupName =
        'trip_meter_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.jsonl';
    final backupFile = File('${dir.path}/$backupName');
    await backupFile.writeAsBytes(await file.readAsBytes());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(backupFile.path)],
        text: 'Backup riwayat Trip Meter',
      ),
    );
  }

  /// Buka file picker untuk memilih file backup (.jsonl), lalu
  /// GABUNGKAN (append, bukan replace) ke riwayat yang ada saat ini.
  /// Mengembalikan jumlah baris yang berhasil ditambahkan.
  /// Melempar exception kalau file tidak valid atau user membatalkan.
  static Future<int> restore() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('Tidak ada file dipilih.');
    }

    final picked = result.files.single;
    final bytes = await picked.readAsBytes();

    final content = String.fromCharCodes(bytes);
    final lines = content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw Exception('File tidak berisi data riwayat yang valid.');
    }

    // Validasi setiap baris adalah JSON SessionRecord yang valid
    // SEBELUM menulis apa pun -- mencegah file riwayat rusak
    // separuh jalan kalau file yang dipilih ternyata bukan backup asli.
    int validCount = 0;
    for (final line in lines) {
      try {
        final decoded = line.trim();
        if (decoded.startsWith('{') &&
            decoded.contains('sessionStartTime') &&
            decoded.contains('totalKmHarian')) {
          validCount++;
        }
      } catch (_) {
        // lewati baris tidak valid, dihitung sebagai gagal
      }
    }

    if (validCount == 0) {
      throw Exception('File yang dipilih bukan format backup Trip Meter yang valid.');
    }

    final file = File(_historyFileName);
    final sink = file.openWrite(mode: FileMode.append);
    for (final line in lines) {
      sink.writeln(line.trim());
    }
    await sink.close();

    return validCount;
  }

  /// Hapus SELURUH riwayat sesi secara permanen.
  static Future<void> clearAllHistory() async {
    await HistoryService.clear();
  }
}
