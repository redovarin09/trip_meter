import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../models/trip_data.dart';
import '../services/background_service.dart';
import '../utils/formatter.dart';
import '../utils/permission_handler.dart';
import 'widgets/metric_card.dart';
import 'widgets/session_buttons.dart';
import 'widgets/summary_dialog.dart';

/// Layar utama (single-page dashboard) — sesuai keputusan Step 1,
/// ini HANYA layar rekap/dashboard, bukan layar kontrol trip.
/// Kontrol trip (MULAI/PAUSE/FINISH TRIP) ada di Notification Panel.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FlutterBackgroundService _service = FlutterBackgroundService();

  TripData _data = const TripData();
  DateTime _now = DateTime.now();

  StreamSubscription<Map<String, dynamic>?>? _updateSub;
  StreamSubscription<Map<String, dynamic>?>? _sessionFinishedSub;
  StreamSubscription<Map<String, dynamic>?>? _tripFinishedSub;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _listenToService();
    _startClock();
  }

  @override
  void dispose() {
    _updateSub?.cancel();
    _sessionFinishedSub?.cancel();
    _tripFinishedSub?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  /// Jam di AppBar update setiap detik — independen dari GPS,
  /// supaya driver tetap lihat waktu real-time meski mobil diam.
  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  void _listenToService() {
    _updateSub = _service.on(ServiceEvent.update).listen((event) {
      if (event == null) return;
      if (mounted) {
        setState(() => _data = TripData.fromJson(event));
      }
    });

    _sessionFinishedSub =
        _service.on(ServiceEvent.sessionFinished).listen((event) {
      if (event == null) return;
      if (!mounted) return;
      final snapshot = TripData.fromJson(event);
      SessionSummaryDialog.show(context, snapshot);
    });

    _tripFinishedSub = _service.on(ServiceEvent.tripFinished).listen((event) {
      if (event == null) return;
      if (!mounted) return;
      final snapshot = TripData.fromJson(event);
      TripSummaryDialog.show(context, snapshot);
    });
  }

  /// Alur MULAI SESI: pastikan semua permission runtime sudah
  /// diberikan SEBELUM service jalan — sesuai requirement
  /// "Android Permissions Wajib ditangani secara runtime".
  Future<void> _handleStartSession() async {
    final foreground = await AppPermissionHandler.requestForegroundLocation();
    if (!mounted) return;
    if (foreground != PermissionResult.granted) {
      _showPermissionDeniedMessage('Lokasi');
      return;
    }

    final background = await AppPermissionHandler.requestBackgroundLocation();
    if (!mounted) return;
    if (background != PermissionResult.granted) {
      _showPermissionDeniedMessage('Lokasi Latar Belakang');
      return;
    }

    await AppPermissionHandler.requestNotificationPermission();
    await AppPermissionHandler.requestIgnoreBatteryOptimization();

    final isRunning = await _service.isRunning();
    if (!isRunning) {
      await _service.startService();
    }

    _service.invoke(ServiceCommand.startSession);
  }

  void _handleFinishSession() {
    _service.invoke(ServiceCommand.finishSession);
  }

  void _showPermissionDeniedMessage(String permissionName) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A1A1A),
        content: Text(
          'Izin $permissionName diperlukan agar Trip Meter berfungsi.',
          style: const TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          label: 'PENGATURAN',
          textColor: const Color(0xFF00FF88),
          onPressed: AppPermissionHandler.openSettings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Akumulasi KM dari trip yang SUDAH selesai (tidak termasuk
    // trip aktif & dead mileage) — untuk info bar bawah.
    final completedTripsKm =
        (_data.totalKmHarian - _data.deadMileage - _data.kmTripAktif)
            .clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              _buildAppBar(),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: MetricCard(
                    label: 'KM / TRIP AKTIF',
                    valueKm: _data.kmTripAktif,
                    size: MetricSize.large,
                    valueColor: const Color(0xFF00FF88),
                  ),
                ),
              ),
              const Divider(color: Color(0xFF1A1A1A), height: 1),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MetricCard(
                    label: 'DEAD MILEAGE',
                    valueKm: _data.deadMileage,
                    sublabel: '☁ Jarak Kosong',
                  ),
                  MetricCard(
                    label: 'TOTAL KM HARIAN',
                    valueKm: _data.totalKmHarian,
                    sublabel: '📍 Hari Ini',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '${Formatter.tripLabel(_data.tripCount)}  ·  '
                'Akumulasi: ${Formatter.kmWithUnit(completedTripsKm)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
              ),
              const SizedBox(height: 20),
              SessionButtons(
                sessionState: _data.sessionState,
                onStartSession: _handleStartSession,
                onFinishSession: _handleFinishSession,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.circle, size: 10, color: Color(0xFF00FF88)),
            const SizedBox(width: 8),
            const Text(
              'TRIP METER',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatter.timeOfDay(_now),
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            Text(
              Formatter.dateShort(_now),
              style: const TextStyle(fontSize: 11, color: Color(0xFF555555)),
            ),
          ],
        ),
      ],
    );
  }
}
