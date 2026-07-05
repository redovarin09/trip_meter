import 'package:flutter/material.dart';

import '../models/session_record.dart';
import '../services/history_service.dart';
import '../utils/formatter.dart';

/// Halaman Riwayat Harian -- menampilkan daftar sesi kerja yang
/// sudah selesai (FINISH SESI), terbaru di atas.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<SessionRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = HistoryService.getAll();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = HistoryService.getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Harian')),
      body: FutureBuilder<List<SessionRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada riwayat sesi.\nSelesaikan sesi pertama Anda untuk melihatnya di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: records.length,
              itemBuilder: (context, index) {
                return _SessionRecordCard(record: records[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _SessionRecordCard extends StatelessWidget {
  final SessionRecord record;

  const _SessionRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF0A0A0A),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatter.dateShort(record.sessionEndTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  Formatter.durationShort(record.duration),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatChip(
                  label: 'Total',
                  value: Formatter.kmWithUnit(record.totalKmHarian),
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Kosongan',
                  value: Formatter.kmWithUnit(record.deadMileage),
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Trip',
                  value: '${record.tripCount}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Efisiensi: ${record.efficiencyPercent.toStringAsFixed(0)}%',
              style: const TextStyle(color: Color(0xFF00FF88), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
