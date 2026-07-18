import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/diagnosis_entity.dart';
import '../bloc/diagnosis_bloc.dart';
import 'diagnosis_result_page.dart';

// =============================================================================
// AgroGraph-MAS -- Historial de Diagnosticos
// =============================================================================


// =============================================================================
// Bottom sheet version (invoked from camera history button)
// =============================================================================
class DiagnosisHistorySheet extends StatefulWidget {
  final ScrollController scrollController;

  const DiagnosisHistorySheet({super.key, required this.scrollController});

  @override
  State<DiagnosisHistorySheet> createState() => _DiagnosisHistorySheetState();
}

class _DiagnosisHistorySheetState extends State<DiagnosisHistorySheet> {
  @override
  void initState() {
    super.initState();
    context.read<DiagnosisBloc>().add(const DiagnosisHistoryRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxlPlus)),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.parcelsTrackGrey,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historial de diagnósticos',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.parcelsTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DiagnosisHistoryFullPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Ver todo',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 0.5, color: AppColors.parcelsBorderLight.withValues(alpha: 0.2)),
          // List
          Expanded(
            child: BlocBuilder<DiagnosisBloc, DiagnosisState>(
              builder: (context, state) {
                if (state is DiagnosisHistoryLoaded) {
                  final items = state.filteredItems;
                  if (items.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return ListView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    itemCount: items.length,
                    itemBuilder: (context, i) => _buildCard(context, items[i]),
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.forestGreen,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.giant),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppColors.parcelsChipGreenBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.parcelsAddGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.xxlPlus),
            Text(
              'Aún no hay diagnósticos',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.parcelsTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Toma tu primera foto para analizar el estado de tus cultivos.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.parcelsTextSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Full screen version
// =============================================================================
class DiagnosisHistoryFullPage extends StatefulWidget {
  const DiagnosisHistoryFullPage({super.key});

  @override
  State<DiagnosisHistoryFullPage> createState() =>
      _DiagnosisHistoryFullPageState();
}

class _DiagnosisHistoryFullPageState extends State<DiagnosisHistoryFullPage> {
  static const List<String> _filters = [
    'Todos',
    'Con alerta',
    'En tratamiento',
    'Saludable',
  ];

  @override
  void initState() {
    super.initState();
    context.read<DiagnosisBloc>().add(const DiagnosisHistoryRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parcelsBg,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Historial de diagnósticos',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      body: BlocBuilder<DiagnosisBloc, DiagnosisState>(
        builder: (context, state) {
          if (state is DiagnosisHistoryLoaded) {
            return Column(
              children: [
                // Filter bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.parcelsBorderLight.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    height: 32,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      itemBuilder: (context, i) {
                        final filterName = _filters[i];
                        final isSelected = filterName == state.activeFilter;
                        return GestureDetector(
                          onTap: () {
                            context.read<DiagnosisBloc>().add(
                              DiagnosisFilterHistory(filterName),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: AppSpacing.md),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.forestGreen
                                  : AppColors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: AppColors.parcelsBorderLight.withValues(alpha: 0.3),
                                      width: 0.5,
                                    ),
                            ),
                            child: Text(
                              filterName,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? AppColors.onPrimary
                                    : AppColors.parcelsTextSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Grouped list
                Expanded(
                  child: state.filteredItems.isEmpty
                      ? _buildEmptyStateFull()
                      : _buildGroupedList(state.filteredItems),
                ),
              ],
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: AppColors.forestGreen),
          );
        },
      ),
    );
  }

  static const List<String> _meses = [
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

  Widget _buildGroupedList(List<DiagnosisEntity> items) {
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
          ...grouped[month]!.map((e) => _buildCard(context, e)),
        ],
      ],
    );
  }

  /// Convierte "6/2026" → "JUNIO 2026"
  String _formatMes(String monthSlash) {
    final parts = monthSlash.split('/');
    if (parts.length != 2) return monthSlash;
    final m = int.tryParse(parts[0]) ?? 0;
    final y = parts[1];
    final nombre = (m >= 1 && m <= 12) ? _meses[m] : monthSlash;
    return '$nombre $y';
  }

  Widget _buildEmptyStateFull() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.giant),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppColors.parcelsChipGreenBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.parcelsAddGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.xxlPlus),
            Text(
              'Aún no hay diagnósticos',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.parcelsTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Toma tu primera foto para analizar el estado de tus cultivos.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.parcelsTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxlPlus),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warmAmber,
                  foregroundColor: AppColors.onWarmAmber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lgXl),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Ir a c\u00e1mara \u2192',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Shared: Diagnosis card (used by both sheet and full screen)
// =============================================================================
Widget _buildCard(BuildContext context, DiagnosisEntity e) {
  Color statusBg = AppColors.parcelsChipGreenBg;
  Color statusText = AppColors.parcelsChipGreenText;
  if (e.statusLabel == 'En tratamiento' || e.statusLabel == 'Seguimiento') {
    statusBg = AppColors.parcelsChipFollowBg;
    statusText = AppColors.parcelsChipFollowText;
  }

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DiagnosisResultPage(diagnosis: e)),
      );
    },
    child: Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.none, AppSpacing.xl, AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.lgXl),
        border: Border.all(
          color: AppColors.parcelsBorderLight.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.diagnosisThumbBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: e.imagePath != null
                ? const Icon(Icons.image, size: 24, color: AppColors.parcelsTextSecondary)
                : const Icon(
                    Icons.eco_outlined,
                    size: 24,
                    color: AppColors.parcelsTextSecondary,
                  ),
          ),
          const SizedBox(width: AppSpacing.xl),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: name + severity dot
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.diseaseName,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.parcelsTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.forestGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxsPlus),
                // Row 2: crop chip
                Row(
                  children: [
                    _buildPill(e.cropName, AppColors.parcelsChipGreenBg, AppColors.parcelsChipGreenText),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Row 3: date + status chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${e.diagnosedAt.day}/${e.diagnosedAt.month}/${e.diagnosedAt.year}',
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.parcelsBorderLight),
                    ),
                    _buildPill(e.statusLabel, statusBg, statusText),
                  ],
                ),
                // Row 4: treatment bar
                if (e.treatmentProgress != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          child: SizedBox(
                            height: 4,
                            child: LinearProgressIndicator(
                              value: e.treatmentProgress!,
                              backgroundColor: AppColors.parcelsTrackGrey,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.forestGreen,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (e.treatmentStep != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          e.treatmentStep!,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: AppColors.parcelsTextSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildPill(String label, Color bg, Color text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.mdLg),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: text,
      ),
    ),
  );
}
