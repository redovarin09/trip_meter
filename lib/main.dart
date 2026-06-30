import 'package:flutter/material.dart';

import 'services/background_service.dart';
import 'ui/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
