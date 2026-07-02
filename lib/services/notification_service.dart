import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_state.dart';
import '../models/trip_data.dart';
import '../services/background_service.dart' show ServiceCommand;
import '../utils/debug_logger.dart';
import '../utils/formatter.dart';

/// Handler untuk notification action dengan showsUserInterface: false.
/// WAJIB top-level function (bukan closure) + @pragma('vm:entry-point'),
/// karena Android menjalankan ini di ISOLATE/Flutter Engine TERPISAH
/// dari isolate background service utama. Kita instantiate
/// FlutterBackgroundService() baru di sini — invoke() akan tetap
/// nyambung ke service asli yang sedang berjalan lewat platform
/// channel, bukan lewat referensi objek Dart langsung.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  DebugLogger.log('[NOTIF] Handler terpanggil, actionId: ${response.actionId}');
  final actionId = response.actionId;
  if (actionId == null) {
    DebugLogger.log('[NOTIF] actionId NULL — berhenti');
    return;
  }

  final service = FlutterBackgroundService();
  switch (actionId) {
    case NotificationAction.startTrip:
      DebugLogger.log('[NOTIF] Invoke startTrip...');
      service.invoke(ServiceCommand.startTrip);
      break;
    case NotificationAction.pauseTrip:
      DebugLogger.log('[NOTIF] Invoke pauseTrip...');
      service.invoke(ServiceCommand.pauseTrip);
      break;
    case NotificationAction.finishTrip:
      DebugLogger.log('[NOTIF] Invoke finishTrip...');
      service.invoke(ServiceCommand.finishTrip);
      break;
  }
}

/// ID notifikasi HARUS SAMA dengan foregroundServiceNotificationId
/// di background_service.dart — supaya notifikasi custom ini
/// "menimpa" notifikasi foreground service bawaan, bukan jadi
/// notifikasi kedua yang terpisah.
const int _kNotificationId = 888;
const String _kChannelId = 'trip_meter_cockpit';
const String _kChannelName = 'Trip Meter Cockpit';

/// ID action — dipakai untuk mapping tombol notifikasi ke command
/// yang dikirim ke background service.
class NotificationAction {
  NotificationAction._();

  static const String startTrip = 'action_start_trip';
  static const String pauseTrip = 'action_pause_trip';
  static const String finishTrip = 'action_finish_trip';
}

/// Mengelola tampilan notifikasi cockpit (custom, dengan tombol aksi).
/// WAJIB di-initialize dari DALAM isolate background service
/// (dipanggil dari background_service.dart), bukan dari UI thread,
/// karena notifikasi ini perlu tetap hidup walau app di-minimize.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Inisialisasi plugin + daftarkan callback saat tombol aksi ditekan.
  /// [onAction] dipanggil dengan actionId saat driver tekan tombol.
  static Future<void> initialize({
    required void Function(String actionId) onAction,
  }) async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final actionId = response.actionId;
        if (actionId != null) {
          onAction(actionId);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  /// Update tampilan notifikasi sesuai TripData terbaru.
  /// Dipanggil setiap kali ada update GPS atau perubahan state
  /// dari background_service.dart.
  static Future<void> update(TripData data) async {
    if (!data.sessionState.isActive) {
      await _plugin.cancel(id: _kNotificationId);
      return;
    }

    switch (data.tripState) {
      case TripState.idle:
        await _showIdle(data);
        break;
      case TripState.running:
        await _showRunning(data);
        break;
      case TripState.paused:
        await _showPaused(data);
        break;
    }
  }

  static Future<void> _showIdle(TripData data) async {
    final details = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: 'Status sesi & kontrol trip',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      icon: '@mipmap/ic_launcher',
      actions: const [
        AndroidNotificationAction(
          NotificationAction.startTrip,
          '▶ MULAI TRIP',
          showsUserInterface: false,
        ),
      ],
    );

    await _plugin.show(
      id: _kNotificationId,
      title: 'Trip Meter — Menunggu Orderan',
      body: 'Dead Mileage: ${Formatter.kmWithUnit(data.deadMileage)}  •  '
          'Total Harian: ${Formatter.kmWithUnit(data.totalKmHarian)}',
      notificationDetails: NotificationDetails(android: details),
    );
  }

  static Future<void> _showRunning(TripData data) async {
    final details = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: 'Status sesi & kontrol trip',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      icon: '@mipmap/ic_launcher',
      actions: const [
        AndroidNotificationAction(
          NotificationAction.pauseTrip,
          '⏸ PAUSE',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          NotificationAction.finishTrip,
          '■ FINISH TRIP',
          showsUserInterface: false,
        ),
      ],
    );

    final elapsed = data.tripStartTime != null
        ? DateTime.now().difference(data.tripStartTime!)
        : Duration.zero;

    await _plugin.show(
      id: _kNotificationId,
      title: 'Trip Meter — Trip Sedang Jalan  ⏱ ${Formatter.duration(elapsed)}',
      body: 'Jarak: ${Formatter.kmWithUnit(data.kmTripAktif)}',
      notificationDetails: NotificationDetails(android: details),
    );
  }

  static Future<void> _showPaused(TripData data) async {
    final details = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: 'Status sesi & kontrol trip',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      icon: '@mipmap/ic_launcher',
      actions: const [
        AndroidNotificationAction(
          NotificationAction.startTrip,
          '▶ LANJUTKAN',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          NotificationAction.finishTrip,
          '■ FINISH TRIP',
          showsUserInterface: false,
        ),
      ],
    );

    await _plugin.show(
      id: _kNotificationId,
      title: 'Trip Meter — Dijeda ⏸',
      body: 'Jarak: ${Formatter.kmWithUnit(data.kmTripAktif)} (dikunci)',
      notificationDetails: NotificationDetails(android: details),
    );
  }
}
