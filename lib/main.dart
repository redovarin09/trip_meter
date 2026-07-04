import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'ui/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // WAJIB didaftarkan dari isolate UI/main SEBELUM runApp() --
  // callback dispatcher untuk background-tap notifikasi hanya
  // ter-register dengan benar kalau initialize() dipanggil di sini.
  // Panggilan initialize() kedua di background_service.dart tetap
  // diperlukan karena _plugin bersifat isolate-local -- isolate
  // service butuh instance sendiri untuk bisa show()/update() notifikasi.
  await NotificationService.initialize(
    onAction: (actionId) {
      final service = FlutterBackgroundService();
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

  // Inisialisasi konfigurasi flutter_background_service.
  // WAJIB sebelum runApp() — service belum DIMULAI di sini,
  // hanya disiapkan. Service baru benar-benar jalan saat
  // driver tekan MULAI SESI (lihat dashboard_screen.dart).
  await initializeBackgroundService();

  runApp(const TripMeterApp());
}

class TripMeterApp extends StatelessWidget {
  const TripMeterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Meter',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const DashboardScreen(),
    );
  }

  /// Tema True Black (AMOLED) + aksen Hijau Neon,
  /// sesuai UI/UX Requirements di project spec.
  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00FF88),
        surface: Colors.black,
      ),
      fontFamily: 'Roboto',
      useMaterial3: true,
    );
  }
}
