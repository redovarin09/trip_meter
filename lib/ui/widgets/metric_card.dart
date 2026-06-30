import 'package:flutter/material.dart';

import '../../utils/formatter.dart';

/// Ukuran tampilan metric card. Dipakai untuk membedakan
/// KM/Trip Aktif (besar, dominan) vs Dead Mileage & Total
/// Harian (sedang, berdampingan) sesuai wireframe Step 1.
enum MetricSize { large, medium }

/// Kartu angka KM dengan label, dioptimalkan untuk dibaca
/// sekilas dari dashboard mobil saat menyetir — font besar,
/// kontras tinggi, minim elemen dekoratif.
class MetricCard extends StatelessWidget {
  final String label;
  final double valueKm;
  final String? sublabel;
  final MetricSize size;
  final Color valueColor;

  const MetricCard({
    super.key,
    required this.label,
    required this.valueKm,
    this.sublabel,
    this.size = MetricSize.medium,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final isLarge = size == MetricSize.large;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 13 : 11,
            color: const Color(0xFF666666),
            letterSpacing: 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: isLarge ? 8 : 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              Formatter.km(valueKm),
              style: TextStyle(
                fontSize: isLarge ? 92 : 42,
                fontWeight: FontWeight.bold,
                color: valueColor,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'km',
              style: TextStyle(
                fontSize: isLarge ? 22 : 16,
                fontWeight: FontWeight.w600,
                color: valueColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        if (sublabel != null) ...[
          SizedBox(height: isLarge ? 4 : 2),
          Text(
            sublabel!,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF444444),
            ),
          ),
        ],
      ],
    );
  }
}
