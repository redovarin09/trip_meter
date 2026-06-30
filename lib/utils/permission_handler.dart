import 'package:permission_handler/permission_handler.dart' as ph;

/// Hasil dari proses request permission, dipakai UI untuk
/// menampilkan pesan/dialog yang sesuai ke driver.
enum PermissionResult {
  /// Semua permission yang dibutuhkan sudah diberikan.
  granted,

  /// Driver menolak salah satu permission (masih bisa diminta lagi).
  denied,

  /// Driver menolak permanen ("Don't ask again") — perlu
  /// arahkan ke Settings aplikasi secara manual.
  permanentlyDenied,
}

/// Mengelola seluruh alur runtime permission yang dibutuhkan
/// aplikasi: lokasi (foreground + background), notifikasi,
/// dan battery optimization exemption.
class AppPermissionHandler {
  AppPermissionHandler._();

  /// TAHAP 1: Minta izin lokasi foreground (WHILE_IN_USE).
  /// Harus berhasil dulu sebelum minta background location —
  /// Android tidak mengizinkan minta keduanya sekaligus.
  static Future<PermissionResult> requestForegroundLocation() async {
    final status = await ph.Permission.locationWhenInUse.request();
    return _mapStatus(status);
  }

  /// TAHAP 2: Minta izin lokasi background (ACCESS_BACKGROUND_LOCATION).
  /// WAJIB dipanggil SETELAH requestForegroundLocation() berhasil.
  /// Di Android 10+, ini akan membuka Settings sistem (bukan dialog
  /// biasa) karena kebijakan Google untuk app yang track lokasi
  /// saat layar mati.
  static Future<PermissionResult> requestBackgroundLocation() async {
    final status = await ph.Permission.locationAlways.request();
    return _mapStatus(status);
  }

  /// TAHAP 3: Minta izin notifikasi (wajib eksplisit di Android 13+).
  /// Tanpa ini, foreground service notification (cockpit utama)
  /// tidak akan tampil sama sekali.
  static Future<PermissionResult> requestNotificationPermission() async {
    final status = await ph.Permission.notification.request();
    return _mapStatus(status);
  }

  /// TAHAP 4: Minta exemption dari battery optimization / Doze Mode.
  /// Tanpa ini, OS bisa membunuh background service secara paksa
  /// setelah beberapa menit layar mati — krusial untuk app ini
  /// karena driver butuh tracking jalan terus selama shift.
  static Future<PermissionResult> requestIgnoreBatteryOptimization() async {
    final status = await ph.Permission.ignoreBatteryOptimizations.request();
    return _mapStatus(status);
  }

  /// Helper: cek semua permission inti (TANPA minta) — dipakai
  /// saat app dibuka untuk tahu apakah perlu tampilkan onboarding
  /// permission lagi atau langsung lanjut ke Dashboard.
  static Future<bool> hasAllCorePermissions() async {
    final foreground = await ph.Permission.locationWhenInUse.isGranted;
    final background = await ph.Permission.locationAlways.isGranted;
    final notification = await ph.Permission.notification.isGranted;

    return foreground && background && notification;
  }

  /// Membuka halaman Settings aplikasi secara manual — dipakai
  /// saat permission permanentlyDenied (driver harus aktifkan
  /// manual dari Settings, app tidak bisa minta dialog lagi).
  static Future<void> openSettings() async {
    await ph.openAppSettings();
  }

  static PermissionResult _mapStatus(ph.PermissionStatus status) {
    if (status.isGranted) {
      return PermissionResult.granted;
    }
    if (status.isPermanentlyDenied) {
      return PermissionResult.permanentlyDenied;
    }
    return PermissionResult.denied;
  }
}
