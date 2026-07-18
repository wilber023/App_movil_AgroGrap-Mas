import 'dart:convert';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/security/local_auth_gate.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../diagnosis/presentation/bloc/diagnosis_bloc.dart';
import '../../../diagnosis/presentation/pages/diagnosis_page.dart';
import '../../domain/entities/parcel_entity.dart';
import '../bloc/parcel_bloc.dart';
import 'add_parcel_page.dart';
import 'parcel_detail_page.dart';

// =============================================================================
// AgroGraph-MAS -- Mis Parcelas (lista principal)
// =============================================================================

class ParcelsPage extends StatelessWidget {
  const ParcelsPage({super.key});

  static const List<String> _stages = [
    'Siembra',
    'Vegetativo',
    'Floracion',
    'Cosecha',
  ];

  static const Map<String, String> _emojiMap = {
    'Calabaza': '🍈',
    'Frijol': '🫘',
    'Manzana': '🍎',
    'Mora': '🫐',
    'Cereza': '🍒',
    'Maíz': '🌽',
    'Durazno': '🍑',
    'Uva': '🍇',
    'Naranja': '🍊',
    'Pimienta': '🌶️',
    'Papa': '🥔',
    'Frambuesa': '🍓',
    'Soja': '🌱',
    'Fresa': '🍓',
    'Tomate': '🍅',
  };

  @override
  Widget build(BuildContext context) {
    return const _ParcelsView();
  }
}

class _ParcelsView extends StatelessWidget {
  const _ParcelsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parcelsBg,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_outlined, color: AppColors.onPrimary),
          onPressed: () {},
        ),
        title: Text(
          'Mis Parcelas',
          style: AppTypography.labelMd.copyWith(
            color: AppColors.onPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_outlined,
              color: AppColors.warmAmber,
              size: 22,
            ),
            onPressed: () => _openAddParcel(context),
          ),
        ],
      ),
      body: BlocConsumer<ParcelBloc, ParcelState>(
        listener: (context, state) {
          if (state is ParcelDeleted) {
            context.read<ParcelBloc>().add(const ParcelLoadRequested());
          }
          if (state is ParcelFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.burntOrange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ParcelLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.forestGreen),
            );
          }
          if (state is ParcelLoaded) {
            if (state.parcels.isEmpty) return _buildEmptyState(context);
            return _buildParcelList(context, state.parcels);
          }
          if (state is ParcelFailure) {
            return _buildErrorState(context, state.message);
          }
          return const Center(
            child: CircularProgressIndicator(color: AppColors.forestGreen),
          );
        },
      ),
    );
  }

  void _openAddParcel(BuildContext context) async {
    final bloc = context.read<ParcelBloc>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddParcelPage()),
    );
    bloc.add(const ParcelLoadRequested());
  }

  // ---------------------------------------------------------------------------
  // Lista de parcelas
  // ---------------------------------------------------------------------------

  Widget _buildParcelList(BuildContext context, List<ParcelEntity> parcels) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.lg, AppSpacing.xxlPlus, AppSpacing.none),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus),
            child: Column(
              children: [
                for (int i = 0; i < parcels.length; i++) ...[
                  _buildParcelCard(context, parcels[i]),
                  if (i < parcels.length - 1) const SizedBox(height: AppSpacing.lg),
                ],
                const SizedBox(height: AppSpacing.lg),
                _buildAddParcelDashed(context),
                const SizedBox(height: AppSpacing.giant),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Barra de búsqueda
  // ---------------------------------------------------------------------------

  Widget _buildSearchBar() {
    return SizedBox(
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.onPrimary,
          borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
          border: Border.all(
            color: AppColors.parcelsBorderLight.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Buscar parcela...',
            hintStyle: AppTypography.etiquetaSm.copyWith(
              color: AppColors.parcelsBorderLight,
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.search_outlined,
              color: AppColors.parcelsTextSecondary,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxlPlus,
              vertical: AppSpacing.xxl,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tarjeta de parcela
  // ---------------------------------------------------------------------------

  Widget _buildParcelCard(BuildContext context, ParcelEntity p) {
    final statusColors = _statusColors(p.status);
    final emoji = ParcelsPage._emojiMap[p.cropName] ?? '🌿';
    final diagCount = _countLocalDiagnoses(p.seleccionId);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ParcelDetailPage(parcel: p)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: AppColors.onPrimary,
              border: Border(
                left: BorderSide(color: statusColors.border, width: 4),
                top: BorderSide(
                  color: AppColors.parcelsBorderLight.withValues(alpha: 0.2),
                  width: 0.5,
                ),
                right: BorderSide(
                  color: AppColors.parcelsBorderLight.withValues(alpha: 0.2),
                  width: 0.5,
                ),
                bottom: BorderSide(
                  color: AppColors.parcelsBorderLight.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji avatar
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.parcelsChipGreenBg,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 25),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.parcelsTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              _chip(p.cropName, AppColors.parcelsChipGreenBg, AppColors.parcelsChipGreenText),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '${p.areaSize.toStringAsFixed(1)} ${p.areaUnit}',
                                style: AppTypography.etiquetaSm.copyWith(
                                  color: AppColors.parcelsTextSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          if (p.region.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xxsPlus),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 11,
                                  color: AppColors.parcelsTextSecondary,
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                Expanded(
                                  child: Text(
                                    p.region,
                                    style: AppTypography.etiquetaSm.copyWith(
                                      color: AppColors.parcelsTextSecondary,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildThreeDotMenu(context, p),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    _statusChip(
                      p.status,
                      statusColors.chipBg,
                      statusColors.chipText,
                      statusColors.icon,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Conteo de diagnósticos locales
                    if (diagCount > 0)
                      _diagCountChip(diagCount)
                    else if (p.lastDiagnosisAt != null) ...[
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.parcelsBorderLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Diag. ${_timeAgo(p.lastDiagnosisAt!)}',
                        style: AppTypography.etiquetaSm.copyWith(
                          color: AppColors.parcelsTextSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildPhenologicalBar(p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Menú de tres puntos con delete funcional
  // ---------------------------------------------------------------------------

  Widget _buildThreeDotMenu(BuildContext context, ParcelEntity p) {
    return SizedBox(
      width: 48,
      height: 48,
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert_outlined,
          color: AppColors.parcelsBorderLight,
          size: 16,
        ),
        onSelected: (value) {
          if (value == 'detalle') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ParcelDetailPage(parcel: p)),
            );
          }
          if (value == 'diagnostico') {
            context.read<DiagnosisBloc>().add(const DiagnosisReset());
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    DiagnosisPage(parcelId: p.seleccionId, parcelName: p.name),
              ),
            );
          }
          if (value == 'eliminar') {
            _confirmDelete(context, p);
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'detalle', child: Text('Ver detalle')),
          const PopupMenuItem(
            value: 'diagnostico',
            child: Text('Nuevo diagnóstico'),
          ),
          PopupMenuItem(
            value: 'eliminar',
            child: Text(
              'Eliminar parcela',
              style: TextStyle(color: AppColors.burntOrange),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ParcelEntity p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar parcela'),
        content: Text(
          '¿Seguro que deseas eliminar "${p.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // MASVS-AUTH: reautenticación adicional antes de una operación
              // destructiva e irreversible.
              final authorized = await LocalAuthGate().authenticate(
                localizedReason:
                    'Confirma tu identidad para eliminar esta parcela',
              );
              if (!authorized || !context.mounted) return;
              context.read<ParcelBloc>().add(
                ParcelDeleteRequested(seleccionId: p.seleccionId),
              );
            },
            child: Text(
              'Eliminar',
              style: TextStyle(color: AppColors.burntOrange),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Barra fenológica
  // ---------------------------------------------------------------------------

  Widget _buildPhenologicalBar(ParcelEntity p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Etapa fenologica',
              style: AppTypography.etiquetaSm.copyWith(
                color: AppColors.parcelsTextSecondary,
                fontSize: 10,
              ),
            ),
            Text(
              p.stageName,
              style: AppTypography.etiquetaSm.copyWith(
                color: AppColors.parcelsTextPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: p.stageProgress,
              backgroundColor: AppColors.parcelsTrackGrey,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.forestGreen,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(ParcelsPage._stages.length, (i) {
            final reached = i <= p.stageIndex;
            return Column(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reached ? AppColors.forestGreen : AppColors.parcelsTrackGrey,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  ParcelsPage._stages[i],
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    color: reached ? AppColors.parcelsTextPrimary : AppColors.parcelsTextSecondary,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Botón dashed "Agregar nueva parcela"
  // ---------------------------------------------------------------------------

  Widget _buildAddParcelDashed(BuildContext context) {
    return GestureDetector(
      onTap: () => _openAddParcel(context),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: AppColors.parcelsAddBorder, radius: 14),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.parcelsBg,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_outlined, color: AppColors.parcelsAddGreen, size: 18),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Agregar nueva parcela',
                style: AppTypography.etiquetaSm.copyWith(
                  color: AppColors.parcelsAddGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Estado vacío
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus),
      child: Column(
        children: [
          _buildSearchBar(),
          const Spacer(),
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.parcelsChipGreenBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_florist_outlined,
              color: AppColors.parcelsAddGreen,
              size: 36,
            ),
          ),
          const SizedBox(height: AppSpacing.xxlPlus),
          Text(
            'Aun no tienes parcelas',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.parcelsTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus),
            child: Text(
              'Registra tu primera parcela para recibir diagnosticos precisos.',
              style: AppTypography.etiquetaSm.copyWith(color: AppColors.parcelsTextSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xxlPlus),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _openAddParcel(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmAmber,
                foregroundColor: AppColors.onWarmAmber,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lgXl),
                ),
              ),
              child: const Text(
                'Registrar parcela',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Estado de error
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xhuge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              color: AppColors.parcelsTextSecondary,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.etiquetaSm.copyWith(color: AppColors.parcelsTextSecondary),
            ),
            const SizedBox(height: AppSpacing.xxlPlus),
            ElevatedButton(
              onPressed: () =>
                  context.read<ParcelBloc>().add(const ParcelLoadRequested()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(color: AppColors.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chips
  // ---------------------------------------------------------------------------

  Widget _chip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxsPlus),
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

  Widget _statusChip(String label, Color bg, Color text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxsPlus),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.mdLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: text),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  int _countLocalDiagnoses(String parcelId) {
    try {
      final box = sl<Box<String>>(instanceName: 'diagnosisBox');
      var count = 0;
      for (final raw in box.values) {
        try {
          final m = jsonDecode(raw) as Map<String, dynamic>;
          if (m['parcelId'] == parcelId) count++;
        } catch (_) {}
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  Widget _diagCountChip(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smMd, vertical: AppSpacing.xxsPlus),
      decoration: BoxDecoration(
        color: AppColors.parcelsChipBlueBg,
        borderRadius: BorderRadius.circular(AppRadius.mdLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.analytics_outlined, size: 10, color: AppColors.parcelsChipBlueText),
          const SizedBox(width: AppSpacing.xxsPlus),
          Text(
            '$count ${count == 1 ? 'diagnóstico' : 'diagnósticos'}',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.parcelsChipBlueText,
            ),
          ),
        ],
      ),
    );
  }

  _StatusColors _statusColors(String status) {
    switch (status) {
      case 'Alerta':
        return _StatusColors(
          border: AppColors.burntOrange,
          chipBg: AppColors.parcelsChipAlertBg,
          chipText: AppColors.parcelsChipAlertText,
          icon: Icons.warning_amber_rounded,
        );
      case 'Seguimiento':
        return _StatusColors(
          border: AppColors.warmAmber,
          chipBg: AppColors.parcelsChipFollowBg,
          chipText: AppColors.parcelsChipFollowText,
          icon: Icons.visibility_outlined,
        );
      case 'Saludable':
        return _StatusColors(
          border: AppColors.forestGreen,
          chipBg: AppColors.parcelsChipGreenBg,
          chipText: AppColors.parcelsChipGreenText,
          icon: Icons.check_circle_outline_rounded,
        );
      default: // 'Sin diagnostico' y cualquier otro
        return _StatusColors(
          border: AppColors.parcelsBorderLight,
          chipBg: AppColors.parcelsNeutralChipBg,
          chipText: AppColors.parcelsTextSecondary,
          icon: Icons.radio_button_unchecked_outlined,
        );
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) {
      return 'hace ${diff.inDays} dia${diff.inDays > 1 ? 's' : ''}';
    }
    if (diff.inHours >= 1) return 'hace ${diff.inHours} h';
    return 'hace un momento';
  }
}

class _StatusColors {
  final Color border;
  final Color chipBg;
  final Color chipText;
  final IconData icon;
  const _StatusColors({
    required this.border,
    required this.chipBg,
    required this.chipText,
    required this.icon,
  });
}

// =============================================================================
// Painter para borde discontinuo (dashed) — sin cambios
// =============================================================================

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  static const double _dashWidth = 6;
  static const double _dashGap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = distance + _dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          paint,
        );
        distance = end + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
