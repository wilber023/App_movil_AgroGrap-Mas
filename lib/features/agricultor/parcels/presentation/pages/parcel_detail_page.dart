import 'dart:io';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../diagnosis/domain/entities/diagnosis_entity.dart';
import '../../../diagnosis/presentation/bloc/diagnosis_bloc.dart';
import '../../../diagnosis/presentation/pages/diagnosis_page.dart';
import '../../../diagnosis/presentation/pages/diagnosis_result_page.dart';
import '../../domain/entities/parcel_entity.dart';

// =============================================================================
// AgroGraph-MAS -- Detalle de Parcela
// =============================================================================


class ParcelDetailPage extends StatelessWidget {
  final ParcelEntity parcel;

  const ParcelDetailPage({super.key, required this.parcel});

  static const Map<String, String> _emojiMap = {
    'Calabaza': '🍈',
    'Frijol': '🫘',
    'Maíz': '🌽',
    'Papa': '🥔',
    'Tomate': '🍅',
  };

  @override
  Widget build(BuildContext context) {
    final emoji = _emojiMap[parcel.cropName] ?? '🌿';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.parcelsBg,
        appBar: AppBar(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_outlined, color: AppColors.onPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                parcel.name,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.onPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$emoji ${parcel.cropName}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.parcelsAppBarSubtitle,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            labelColor: AppColors.onPrimary,
            unselectedLabelColor: AppColors.parcelsAppBarSubtitle,
            indicatorColor: AppColors.warmAmber,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
            tabs: [
              Tab(text: 'Resumen'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ResumenTab(parcel: parcel, emojiMap: _emojiMap),
            BlocProvider(
              create: (_) => sl<DiagnosisBloc>()
                ..add(
                  DiagnosisParcelHistoryRequested(parcelId: parcel.seleccionId),
                ),
              child: _HistorialTab(parcel: parcel),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _navigateToDiagnosis(context),
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.onPrimary,
          elevation: 3,
          icon: const Icon(Icons.camera_alt_outlined),
          label: Text(
            'Diagnosticar',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
    );
  }

  void _navigateToDiagnosis(BuildContext context) {
    // Limpia estado residual del bloc raíz antes de abrir la cámara
    context.read<DiagnosisBloc>().add(const DiagnosisReset());
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiagnosisPage(
          parcelId: parcel.seleccionId,
          parcelName: parcel.name,
        ),
      ),
    );
  }
}

// =============================================================================
// Tab 1: Resumen
// =============================================================================

class _ResumenTab extends StatelessWidget {
  final ParcelEntity parcel;
  final Map<String, String> emojiMap;

  const _ResumenTab({required this.parcel, required this.emojiMap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.behemoth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeroCard(),
          const SizedBox(height: AppSpacing.xl),
          _buildTimelineCard(),
          const SizedBox(height: AppSpacing.xl),
          _buildDataCard(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hero card
  // ---------------------------------------------------------------------------

  Widget _buildHeroCard() {
    final statusBg = _statusBg(parcel.status);
    final statusText = _statusTextColor(parcel.status);
    final emoji = emojiMap[parcel.cropName] ?? '🌿';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji del cultivo
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.parcelsChipGreenBg,
                  borderRadius: BorderRadius.circular(AppRadius.lgXl),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcel.name,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.parcelsTextPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxsPlus),
                    Text(
                      parcel.cropName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.parcelsTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (parcel.status != 'Sin diagnostico')
                _chip(parcel.status, statusBg, statusText),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          const Divider(height: 1, thickness: 0.5, color: AppColors.parcelsDividerLight),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _infoTile(
                Icons.crop_square_outlined,
                '${parcel.areaSize.toStringAsFixed(1)} ${parcel.areaUnit}',
                'Superficie',
              ),
              if (parcel.region.isNotEmpty) ...[
                _infoTile(Icons.location_on_outlined, parcel.region, 'Región'),
              ],
              _infoTile(Icons.timeline_outlined, parcel.stageName, 'Etapa'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.parcelsTextSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.parcelsTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.parcelsTextSecondary),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Timeline fenológico moderno
  // ---------------------------------------------------------------------------

  Widget _buildTimelineCard() {
    const stages = [
      (Icons.spa_outlined, 'Siembra', 'Establecimiento del cultivo'),
      (Icons.eco_outlined, 'Vegetativo', 'Crecimiento de hojas y tallos'),
      (Icons.local_florist_outlined, 'Floración', 'Desarrollo floral'),
      (Icons.agriculture_outlined, 'Cosecha', 'Madurez y recolección'),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ciclo fenológico',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.parcelsTextPrimary,
                ),
              ),
              if (parcel.fechaSiembra != null)
                Text(
                  'Siembra: ${_formatDate(parcel.fechaSiembra!)}',
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.parcelsTextSecondary),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxlPlus),
          ...List.generate(stages.length, (i) {
            final (icon, label, desc) = stages[i];
            final isCompleted = i < parcel.stageIndex;
            final isCurrent = i == parcel.stageIndex;
            final isFuture = i > parcel.stageIndex;
            final isLast = i == stages.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna izquierda: círculo + línea
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      Container(
                        width: isCurrent ? 26 : 18,
                        height: isCurrent ? 26 : 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFuture
                              ? AppColors.transparent
                              : isCompleted
                              ? AppColors.forestGreen
                              : AppColors.onPrimary,
                          border: Border.all(
                            color: isFuture
                                ? AppColors.parcelsTrackGrey
                                : AppColors.forestGreen,
                            width: isCurrent ? 2.5 : 1.5,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 10,
                                  color: AppColors.onPrimary,
                                )
                              : isCurrent
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.forestGreen,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 48,
                          color: i < parcel.stageIndex
                              ? AppColors.forestGreen
                              : AppColors.parcelsTrackGrey,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // Columna derecha: label + descripción
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: isCurrent ? AppSpacing.hairline : AppSpacing.none,
                      bottom: isLast ? AppSpacing.none : AppSpacing.giantMinus,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              icon,
                              size: 14,
                              color: isFuture
                                  ? AppColors.parcelsBorderLight
                                  : AppColors.forestGreen,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              label,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isFuture ? AppColors.parcelsTextSecondary : AppColors.parcelsTextPrimary,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.forestGreen,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Text(
                                  'Actual',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          desc,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isFuture ? AppColors.parcelsBorderLight : AppColors.parcelsTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Datos registrados
  // ---------------------------------------------------------------------------

  Widget _buildDataCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos registrados',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.parcelsTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _dataRow(Icons.eco_outlined, 'Cultivo', parcel.cropName),
          _divider(),
          _dataRow(
            Icons.crop_square_outlined,
            'Superficie',
            '${parcel.areaSize.toStringAsFixed(1)} ${parcel.areaUnit}',
          ),
          if (parcel.region.isNotEmpty) ...[
            _divider(),
            _dataRow(Icons.location_on_outlined, 'Región', parcel.region),
          ],
          if (parcel.fechaSiembra != null) ...[
            _divider(),
            _dataRow(
              Icons.calendar_today_outlined,
              'Fecha de siembra',
              _formatDate(parcel.fechaSiembra!),
            ),
          ],
          _divider(),
          _dataRow(Icons.timeline_outlined, 'Etapa actual', parcel.stageName),
          _divider(),
          _dataRow(
            Icons.monitor_heart_outlined,
            'Estado de salud',
            parcel.status,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _dataRow(IconData icon, String label, String value) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.parcelsTextSecondary),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.parcelsTextSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.parcelsTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    thickness: 0.5,
    color: AppColors.parcelsBorderLight.withValues(alpha: 0.2),
  );

  Widget _chip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.mdLg),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.onPrimary,
    borderRadius: BorderRadius.circular(AppRadius.xl),
    border: Border.all(color: AppColors.parcelsBorderLight.withValues(alpha: 0.3), width: 0.5),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  Color _statusBg(String status) {
    switch (status) {
      case 'Alerta':
        return AppColors.parcelsChipAlertBg;
      case 'Seguimiento':
        return AppColors.parcelsChipFollowBg;
      default:
        return AppColors.parcelsChipGreenBg;
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'Alerta':
        return AppColors.parcelsChipAlertText;
      case 'Seguimiento':
        return AppColors.parcelsChipFollowText;
      default:
        return AppColors.parcelsChipGreenText;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// =============================================================================
// Tab 2: Historial de diagnósticos filtrado por parcela
// =============================================================================

class _HistorialTab extends StatelessWidget {
  final ParcelEntity parcel;

  const _HistorialTab({required this.parcel});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiagnosisBloc, DiagnosisState>(
      builder: (context, state) {
        if (state is DiagnosisHistoryLoaded) {
          if (state.filteredItems.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.behemoth),
            itemCount: state.filteredItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
            itemBuilder: (context, i) {
              final dx = state.filteredItems[i];
              return _DiagnosisCard(
                diagnosis: dx,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiagnosisResultPage(diagnosis: dx),
                  ),
                ),
              );
            },
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: AppColors.forestGreen),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.giant),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.parcelsChipGreenBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.forestGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.xxlPlus),
            Text(
              'Sin diagnósticos para esta parcela',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.parcelsTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Usa el botón "Diagnosticar" para analizar el cultivo con el modelo CNN.',
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
// Card de un diagnóstico en el historial
// =============================================================================

class _DiagnosisCard extends StatelessWidget {
  final DiagnosisEntity diagnosis;
  final VoidCallback onTap;

  const _DiagnosisCard({required this.diagnosis, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final confidencePct = (diagnosis.confidence * 100).toStringAsFixed(1);
    final confidenceColor = diagnosis.confidence >= 0.80
        ? AppColors.forestGreen
        : diagnosis.confidence >= 0.60
        ? AppColors.parcelsChipFollowText
        : AppColors.parcelsChipAlertText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.onPrimary,
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          border: Border.all(
            color: AppColors.parcelsBorderLight.withValues(alpha: 0.3),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Miniatura de la imagen analizada
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lgXl),
                bottomLeft: Radius.circular(AppRadius.lgXl),
              ),
              child: SizedBox(
                width: 84,
                height: 96,
                child:
                    diagnosis.imagePath != null &&
                        File(diagnosis.imagePath!).existsSync()
                    ? Image.file(File(diagnosis.imagePath!), fit: BoxFit.cover)
                    : Container(
                        color: AppColors.parcelsChipGreenBg,
                        child: const Icon(
                          Icons.eco_outlined,
                          color: AppColors.forestGreen,
                          size: 28,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            // Información
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diagnosis.diseaseName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.parcelsTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxsPlus),
                    Text(
                      diagnosis.cropName,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.parcelsTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.smMd),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _miniChip(
                          '$confidencePct%',
                          confidenceColor.withValues(alpha: 0.12),
                          confidenceColor,
                        ),
                        _miniChip(
                          diagnosis.statusLabel,
                          _statusBg(diagnosis.statusLabel),
                          _statusTextColor(diagnosis.statusLabel),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xsPlus),
                    Text(
                      _formatDate(diagnosis.diagnosedAt),
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.parcelsBorderLight),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Icon(
                Icons.chevron_right_outlined,
                color: AppColors.parcelsBorderLight,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.smMd),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Alerta':
        return AppColors.parcelsChipAlertBg;
      case 'Seguimiento':
        return AppColors.parcelsChipFollowBg;
      case 'Saludable':
        return AppColors.parcelsChipGreenBg;
      default:
        return AppColors.parcelsChipBlueBg;
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'Alerta':
        return AppColors.parcelsChipAlertText;
      case 'Seguimiento':
        return AppColors.parcelsChipFollowText;
      case 'Saludable':
        return AppColors.parcelsChipGreenText;
      default:
        return AppColors.parcelsChipBlueText;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
