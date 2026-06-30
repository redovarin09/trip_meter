import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import '../models/app_state.dart';
import '../models/trip_data.dart';
import 'gps_service.dart';
import 'notification_service.dart';

/// Command yang bisa dikirim dari UI (Dashboard) atau Notification
/// Panel ke background service. Nama harus persis sama dengan yang
/// dipakai service.on(...) di bawah.
class ServiceCommand {
  ServiceCommand._();

  static const String startSession = 'startSession';
  static const String finishSession = 'finishSession';
  static const String startTrip = 'startTrip';
  static const String pauseTrip = 'pauseTrip';
  static const String finishTrip = 'finishTrip';
}

/// Event yang di-broadcast dari background service ke UI.
class ServiceEvent {
  ServiceEvent._();

  /// Update rutin: kirim seluruh TripData terbaru (untuk Dashboard
  /// & Notification Panel).
  static const String update = 'update';

  /// Sesi selesai: kirim snapshot data SEBELUM direset, untuk
  /// ditampilkan di Dialog Summary FINISH SESI.
  static const String sessionFinished = 'sessionFinished';

  /// Trip selesai: kirim snapshot trip SEBELUM direset, untuk
  /// ditampilkan di Dialog Summary FINISH TRIP.
  static const String tripFinished = 'tripFinished';
}

/// Inisialisasi konfigurasi flutter_background_service.
/// WAJIB dipanggil sekali dari main.dart sebelum runApp().
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onServiceStart,
      autoStart: false,
      isForegroundMode: true,
      foregroundServiceNotificationId: 888,
      initialNotificationTitle: 'Trip Meter',
      initialNotificationContent: 'Menyiapkan layanan...',
    ),
    iosConfiguration: IosConfiguration(),
  );
}

/// Entry point yang jalan di ISOLATE TERPISAH dari UI utama.
/// Semua variable di sini hidup selama service berjalan, terpisah
/// dari lifecycle widget Flutter biasa.
@pragma('vm:entry-point')
void _onServiceStart(ServiceInstance service) async {
  // ═══ STATE LOKAL ISOLATE INI ═══
  TripData tripData = const TripData();
  DateTime? lastPositionTimestamp;
  StreamSubscription<Position>? positionSubscription;

  void broadcastUpdate() {
    service.invoke(ServiceEvent.update, tripData.toJson());
    NotificationService.update(tripData);
  }

  // Inisialisasi notification service + mapping tombol notifikasi
  // ke command yang sesuai. Listener ini jalan SELAMA service hidup.
  await NotificationService.initialize(
    onAction: (actionId) {
      switch (actionId) {
        case NotificationAction.startTrip:
          service.invoke(ServiceCommand.startTrip);
          break;
        case NotificationAction.pauseTrip:
          service.invoke(ServiceCommand.pauseTrip);
          break;
        case NotificationAction.finishTrip:
          service.invoke(ServiceCommand.finishTrip);
          break;
      }
    },
  );

  void startGpsTracking() {
    positionSubscription?.cancel();
    positionSubscription = GpsService.positionStream.listen((position) {
      if (tripData.lastLatitude != null && lastPositionTimestamp != null) {
        final delta = GpsService.calculateDelta(
          prevLat: tripData.lastLatitude!,
          prevLon: tripData.lastLongitude!,
          prevTimestamp: lastPositionTimestamp!,
          newPosition: position,
        );

        if (delta != null) {
          if (tripData.tripState.shouldAccumulateTripDistance) {
            tripData = tripData.copyWith(
              kmTripAktif: tripData.kmTripAktif + delta.distanceKm,
              totalKmHarian: tripData.totalKmHarian + delta.distanceKm,
            );
          } else if (tripData.tripState.shouldAccumulateDeadMileage) {
            tripData = tripData.copyWith(
              deadMileage: tripData.deadMileage + delta.distanceKm,
              totalKmHarian: tripData.totalKmHarian + delta.distanceKm,
            );
          }
        }
      }

      tripData = tripData.copyWith(
        lastLatitude: position.latitude,
        lastLongitude: position.longitude,
      );
      lastPositionTimestamp = position.timestamp;

      broadcastUpdate();
    });
  }

  void stopGpsTracking() {
    positionSubscription?.cancel();
    positionSubscription = null;
  }

  // ═══ COMMAND HANDLERS ═══

  service.on(ServiceCommand.startSession).listen((_) {
    if (tripData.sessionState.isActive) return;

    tripData = tripData.copyWith(
      sessionState: SessionState.active,
      tripState: TripState.idle,
      sessionStartTime: DateTime.now(),
    );

    startGpsTracking(); // mulai akumulasi Dead Mileage
    broadcastUpdate();
  });

  service.on(ServiceCommand.finishSession).listen((_) {
    if (!tripData.sessionState.isActive) return;

    stopGpsTracking();

    // Kirim snapshot SEBELUM direset, untuk Dialog Summary FINISH SESI.
    service.invoke(ServiceEvent.sessionFinished, tripData.toJson());

    tripData = tripData.resetSession();
    lastPositionTimestamp = null;
    broadcastUpdate();
  });

  service.on(ServiceCommand.startTrip).listen((_) {
    if (!tripData.sessionState.isActive) return;
    if (tripData.tripState.isRunning) return;

    final isResuming = tripData.tripState.isPaused;

    tripData = tripData.copyWith(
      tripState: TripState.running,
      // Resume dari pause: pertahankan waktu mulai asli (timer lanjut).
      // Trip baru dari idle: catat waktu mulai baru.
      tripStartTime: isResuming ? tripData.tripStartTime : DateTime.now(),
    );

    startGpsTracking();
    broadcastUpdate();
  });

  service.on(ServiceCommand.pauseTrip).listen((_) {
    if (!tripData.tripState.isRunning) return;

    tripData = tripData.copyWith(tripState: TripState.paused);
    stopGpsTracking(); // GPS dijeda, metrik beku
    broadcastUpdate();
  });

  service.on(ServiceCommand.finishTrip).listen((_) {
    if (tripData.tripState.isIdle) return;

    // Kirim snapshot SEBELUM direset, untuk Dialog Summary FINISH TRIP.
    service.invoke(ServiceEvent.tripFinished, tripData.toJson());

    tripData = tripData.resetTrip();

    // Sesi masih aktif → lanjut tracking Dead Mileage.
    startGpsTracking();
    broadcastUpdate();
  });

  // Kirim state awal begitu service siap.
  broadcastUpdate();
}
