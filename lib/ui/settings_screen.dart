import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/backup_restore_service.dart';

/// Halaman Pengaturan -- info versi, backup/restore riwayat,
/// dan hapus semua riwayat sesi.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _info;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _info = info);
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleBackup() async {
    setState(() => _busy = true);
    try {
      await BackupRestoreService.backup();
    } catch (e) {
      _showMessage('Gagal backup: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _busy = true);
    try {
      final count = await BackupRestoreService.restore();
      _showMessage('Berhasil restore $count sesi riwayat.');
    } catch (e) {
      _showMessage('Gagal restore: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('Hapus Semua Riwayat?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Semua data riwayat sesi akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await BackupRestoreService.clearAllHistory();
      _showMessage('Semua riwayat telah dihapus.');
    } catch (e) {
      _showMessage('Gagal menghapus: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Opacity(
          opacity: _busy ? 0.5 : 1.0,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionTitle('Data'),
              _SettingsTile(
                icon: Icons.upload_file,
                title: 'Backup Riwayat',
                subtitle: 'Bagikan file riwayat via WhatsApp/Drive/Email',
                onTap: _handleBackup,
              ),
              _SettingsTile(
                icon: Icons.download,
                title: 'Restore Riwayat',
                subtitle: 'Pulihkan riwayat dari file backup',
                onTap: _handleRestore,
              ),
              _SettingsTile(
                icon: Icons.delete_forever,
                title: 'Hapus Semua Riwayat',
                subtitle: 'Hapus permanen seluruh data sesi',
                iconColor: Colors.red,
                onTap: _handleClearHistory,
              ),
              const SizedBox(height: 24),
              _SectionTitle('Tentang'),
              _SettingsTile(
                icon: Icons.info_outline,
                title: _info?.appName ?? 'Trip Meter',
                subtitle: _info == null
                    ? 'Memuat...'
                    : 'Versi ${_info!.version} (build ${_info!.buildNumber})',
                onTap: null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF00FF88),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0A0A0A),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? const Color(0xFF00FF88)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        onTap: onTap,
      ),
    );
  }
}
