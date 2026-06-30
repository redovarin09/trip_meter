import 'package:flutter/material.dart';

import '../../models/app_state.dart';

/// Tombol kontrol SESI HARIAN untuk Dashboard.
/// Sesuai keputusan Step 1: Dashboard TIDAK punya tombol
/// trip (MULAI TRIP/PAUSE/FINISH TRIP) — itu hanya ada
/// di Notification Panel.
class SessionButtons extends StatelessWidget {
  final SessionState sessionState;
  final VoidCallback onStartSession;
  final VoidCallback onFinishSession;

  const SessionButtons({
    super.key,
    required this.sessionState,
    required this.onStartSession,
    required this.onFinishSession,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = sessionState.isActive;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isActive ? null : onStartSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF88),
              disabledBackgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.black,
              disabledForegroundColor: const Color(0xFF555555),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              isActive ? 'SESI BERJALAN...' : '▶  MULAI SESI HARI INI',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isActive ? onFinishSession : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4444),
              disabledBackgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              disabledForegroundColor: const Color(0xFF555555),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              '■  FINISH SESI & REKAP',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
