import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/diagnosis_entity.dart';
import 'diagnosis_history_card.dart';

const _meses = [
  '',
  'ENERO',
  'FEBRERO',
  'MARZO',
  'ABRIL',
  'MAYO',
  'JUNIO',
  'JULIO',
  'AGOSTO',
  'SEPTIEMBRE',
  'OCTUBRE',
  'NOVIEMBRE',
  'DICIEMBRE',
];

/// Convierte "6/2026" → "JUNIO 2026"
String _formatMes(String monthSlash) {
  final parts = monthSlash.split('/');
  if (parts.length != 2) return monthSlash;
  final m = int.tryParse(parts[0]) ?? 0;
  final y = parts[1];
  final nombre = (m >= 1 && m <= 12) ? _meses[m] : monthSlash;
  return '$nombre $y';
}

/// Lista de diagnósticos agrupados por mes, usada en
/// [DiagnosisHistoryFullPage].
class DiagnosisHistoryGroupedList extends StatelessWidget {
  const DiagnosisHistoryGroupedList({super.key, required this.items});

  final List<DiagnosisEntity> items;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<DiagnosisEntity>>{};
    for (final e in items) {
      final monthStr = '${e.diagnosedAt.month}/${e.diagnosedAt.year}';
      grouped.putIfAbsent(monthStr, () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      children: [
        for (final month in grouped.keys) ...[
          // Encabezado de mes en español
          Container(
            width: double.infinity,
            color: AppColors.parcelsBg,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
            child: Text(
              _formatMes(month),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.parcelsTextSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...grouped[month]!.map((e) => DiagnosisHistoryCard(diagnosis: e)),
        ],
      ],
    );
  }
}
