import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/diagnosis_entity.dart';
import '../bloc/diagnosis_bloc.dart';
import 'diagnosis_result_page.dart';

// =============================================================================
// AgroGraph-MAS -- Historial de Diagnosticos
// =============================================================================

const Color _bg = Color(0xFFF8FAF5);
const Color _textPrimary = Color(0xFF1B2D27);
const Color _textSecondary = Color(0xFF6B8F71);
const Color _hintColor = Color(0xFFADB5BD);
const Color _chipGreenBg = Color(0xFFEAF3DE);
const Color _chipGreenText = Color(0xFF27500A);
const Color _chipWarnBg = Color(0xFFFFF3E0);
const Color _chipWarnText = Color(0xFF7B4A10);
const Color _trackGrey = Color(0xFFE2EBE6);
const Color _addGreen = Color(0xFF52B788);

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
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: _trackGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historial de diagnósticos',
                  style: AppTypography.labelMd.copyWith(
                    color: _textPrimary,
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
          Container(height: 0.5, color: _hintColor.withValues(alpha: 0.2)),
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
                    padding: const EdgeInsets.only(top: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: _chipGreenBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: _addGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no hay diagnósticos',
              style: AppTypography.labelMd.copyWith(
                color: _textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toma tu primera foto para analizar el estado de tus cultivos.',
              style: GoogleFonts.inter(fontSize: 12, color: _textSecondary),
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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
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
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: _hintColor.withValues(alpha: 0.2),
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
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.forestGreen
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: _hintColor.withValues(alpha: 0.3),
                                      width: 0.5,
                                    ),
                            ),
                            child: Text(
                              filterName,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : _textSecondary,
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
      padding: const EdgeInsets.only(top: 4),
      children: [
        for (final month in grouped.keys) ...[
          // Encabezado de mes en español
          Container(
            width: double.infinity,
            color: _bg,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              _formatMes(month),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: _chipGreenBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: _addGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no hay diagnósticos',
              style: AppTypography.labelMd.copyWith(
                color: _textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toma tu primera foto para analizar el estado de tus cultivos.',
              style: GoogleFonts.inter(fontSize: 12, color: _textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warmAmber,
                  foregroundColor: const Color(0xFF4A2800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
  Color statusBg = _chipGreenBg;
  Color statusText = _chipGreenText;
  if (e.statusLabel == 'En tratamiento' || e.statusLabel == 'Seguimiento') {
    statusBg = _chipWarnBg;
    statusText = _chipWarnText;
  }

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DiagnosisResultPage(diagnosis: e)),
      );
    },
    child: Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hintColor.withValues(alpha: 0.3),
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
              color: const Color(0xFFD8EAD0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: e.imagePath != null
                ? const Icon(Icons.image, size: 24, color: _textSecondary)
                : const Icon(
                    Icons.eco_outlined,
                    size: 24,
                    color: _textSecondary,
                  ),
          ),
          const SizedBox(width: 12),
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
                        color: _textPrimary,
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
                const SizedBox(height: 3),
                // Row 2: crop chip
                Row(
                  children: [
                    _buildPill(e.cropName, _chipGreenBg, _chipGreenText),
                  ],
                ),
                const SizedBox(height: 6),
                // Row 3: date + status chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${e.diagnosedAt.day}/${e.diagnosedAt.month}/${e.diagnosedAt.year}',
                      style: GoogleFonts.inter(fontSize: 10, color: _hintColor),
                    ),
                    _buildPill(e.statusLabel, statusBg, statusText),
                  ],
                ),
                // Row 4: treatment bar
                if (e.treatmentProgress != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            height: 4,
                            child: LinearProgressIndicator(
                              value: e.treatmentProgress!,
                              backgroundColor: _trackGrey,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.forestGreen,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (e.treatmentStep != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          e.treatmentStep!,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: _textSecondary,
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
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(10),
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
