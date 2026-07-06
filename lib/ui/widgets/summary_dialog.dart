import 'package:flutter/material.dart';

import '../../models/trip_data.dart';
import '../../utils/formatter.dart';

/// Dialog rekap saat FINISH SESI ditekan — tampilkan seluruh
/// metrik hari itu sebelum semuanya direset ke 0.
class SessionSummaryDialog extends StatelessWidget {
  final TripData data;

  const SessionSummaryDialog({super.key, required this.data});

  static Future<void> show(BuildContext context, TripData data) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SessionSummaryDialog(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workDuration = data.sessionStartTime != null
        ? DateTime.now().difference(data.sessionStartTime!)
        : Duration.zero;

    return Dialog(
      backgroundColor: const Color(0xFF0A0A0A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '✅ SESI HARIAN SELESAI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00FF88),
              ),
            ),
            const SizedBox(height: 20),
            _SummaryRow(label: 'Total Trip', value: '${data.tripCount} trip'),
            _SummaryRow(
              label: 'Dead Mileage',
              value: Formatter.kmWithUnit(data.deadMileage),
            ),
            _SummaryRow(
              label: 'Total KM Harian',
              value: Formatter.kmWithUnit(data.totalKmHarian),
            ),
            _SummaryRow(
              label: 'Durasi Kerja',
              value: Formatter.durationShort(workDuration),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF88),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'TUTUP',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog rekap saat FINISH TRIP ditekan — ringkas, hanya jarak
/// & durasi trip yang baru selesai. Muncul di App UI (bukan
/// notifikasi), sesuai requirement: "FINISH ditekan → buka App UI
/// → tampilkan Dialog Summary".
class TripSummaryDialog extends StatelessWidget {
  final TripData data;

  const TripSummaryDialog({super.key, required this.data});

  static Future<void> show(BuildContext context, TripData data) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TripSummaryDialog(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripDuration = data.tripStartTime != null
        ? DateTime.now().difference(data.tripStartTime!)
        : Duration.zero;

    return Dialog(
      backgroundColor: const Color(0xFF0A0A0A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '✅ TRIP SELESAI!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00FF88),
              ),
            ),
            const SizedBox(height: 20),
            _SummaryRow(
              label: 'Jarak Trip',
              value: Formatter.kmWithUnit(data.kmTripAktif),
            ),
            _SummaryRow(
              label: 'Durasi',
              value: Formatter.duration(tripDuration),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF88),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'TUTUP',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris label-value di dalam dialog rekap. Internal widget,
/// dipakai oleh SessionSummaryDialog & TripSummaryDialog.
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
