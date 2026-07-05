import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/session_record.dart';
import '../utils/formatter.dart';

/// Mengekspor daftar SessionRecord menjadi file CSV, lalu membuka
/// share sheet Android (WhatsApp, Email, Drive, dsb) untuk dibagikan.
/// Dipanggil dari isolate UI (HistoryScreen), bukan isolate service.
class ExportService {
  ExportService._();

  /// Generate file CSV dari [records], simpan ke direktori sementara,
  /// lalu buka share sheet. Melempar exception kalau gagal --
  /// pemanggil (UI) bertanggung jawab menampilkan pesan error.
  static Future<void> exportAndShare(List<SessionRecord> records) async {
    final rows = <List<String>>[
      ['Tanggal', 'Jam Mulai', 'Jam Selesai', 'Durasi', 'Total KM',
       'KM Kosongan', 'KM Efektif', 'Jumlah Trip', 'Efisiensi (%)'],
    ];

    for (final r in records) {
      rows.add([
        Formatter.dateShort(r.sessionEndTime),
        Formatter.timeOfDay(r.sessionStartTime),
        Formatter.timeOfDay(r.sessionEndTime),
        Formatter.duration(r.duration),
        Formatter.km(r.totalKmHarian),
        Formatter.km(r.deadMileage),
        Formatter.km(r.effectiveKm),
        '${r.tripCount}',
        r.efficiencyPercent.toStringAsFixed(1),
      ]);
    }

    final csvString = const ListToCsvConverter().convert(rows);

    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final fileName =
        'trip_meter_riwayat_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Riwayat Trip Meter (${records.length} sesi)',
      ),
    );
  }
}
