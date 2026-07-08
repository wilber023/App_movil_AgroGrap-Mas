import 'dart:convert';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/security/local_auth_gate.dart';
import '../../../../../core/theme/app_colors.dart';
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

const Color _bg = Color(0xFFF8FAF5);
const Color _textPrimary = Color(0xFF1B2D27);
const Color _textSecondary = Color(0xFF6B8F71);
const Color _borderLight = Color(0xFFADB5BD);
const Color _chipGreenBg = Color(0xFFEAF3DE);
const Color _chipGreenText = Color(0xFF27500A);
const Color _chipAlertBg = Color(0xFFFDECEA);
const Color _chipAlertText = Color(0xFFA32D2D);
const Color _chipFollowBg = Color(0xFFFFF3E0);
const Color _chipFollowText = Color(0xFF7B4A10);
const Color _trackGrey = Color(0xFFE2EBE6);
const Color _chipBlueBg = Color(0xFFE6F1FB);
const Color _chipBlueText = Color(0xFF0C447C);
const Color _addGreen = Color(0xFF52B788);
const Color _addBorder = Color(0xFFA8C5B0);

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
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_outlined, color: Colors.white),
          onPressed: () {},
        ),
        title: Text(
          'Mis Parcelas',
          style: AppTypography.labelMd.copyWith(
            color: Colors.white,
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (int i = 0; i < parcels.length; i++) ...[
                  _buildParcelCard(context, parcels[i]),
                  if (i < parcels.length - 1) const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
                _buildAddParcelDashed(context),
                const SizedBox(height: 32),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _borderLight.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Buscar parcela...',
            hintStyle: AppTypography.etiquetaSm.copyWith(
              color: _borderLight,
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.search_outlined,
              color: _textSecondary,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
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
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(color: statusColors.border, width: 4),
                top: BorderSide(
                  color: _borderLight.withValues(alpha: 0.2),
                  width: 0.5,
                ),
                right: BorderSide(
                  color: _borderLight.withValues(alpha: 0.2),
                  width: 0.5,
                ),
                bottom: BorderSide(
                  color: _borderLight.withValues(alpha: 0.2),
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
                        color: _chipGreenBg,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 25),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: AppTypography.labelMd.copyWith(
                              color: _textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _chip(p.cropName, _chipGreenBg, _chipGreenText),
                              const SizedBox(width: 6),
                              Text(
                                '${p.areaSize.toStringAsFixed(1)} ${p.areaUnit}',
                                style: AppTypography.etiquetaSm.copyWith(
                                  color: _textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          if (p.region.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 11,
                                  color: _textSecondary,
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    p.region,
                                    style: AppTypography.etiquetaSm.copyWith(
                                      color: _textSecondary,
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statusChip(
                      p.status,
                      statusColors.chipBg,
                      statusColors.chipText,
                      statusColors.icon,
                    ),
                    const SizedBox(width: 6),
                    // Conteo de diagnósticos locales
                    if (diagCount > 0)
                      _diagCountChip(diagCount)
                    else if (p.lastDiagnosisAt != null) ...[
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: _borderLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Diag. ${_timeAgo(p.lastDiagnosisAt!)}',
                        style: AppTypography.etiquetaSm.copyWith(
                          color: _textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
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
          color: _borderLight,
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
                color: _textSecondary,
                fontSize: 10,
              ),
            ),
            Text(
              p.stageName,
              style: AppTypography.etiquetaSm.copyWith(
                color: _textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: p.stageProgress,
              backgroundColor: _trackGrey,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.forestGreen,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
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
                    color: reached ? AppColors.forestGreen : _trackGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ParcelsPage._stages[i],
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    color: reached ? _textPrimary : _textSecondary,
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
        painter: _DashedBorderPainter(color: _addBorder, radius: 14),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_outlined, color: _addGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                'Agregar nueva parcela',
                style: AppTypography.etiquetaSm.copyWith(
                  color: _addGreen,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSearchBar(),
          const Spacer(),
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: _chipGreenBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_florist_outlined,
              color: _addGreen,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aun no tienes parcelas',
            style: AppTypography.labelMd.copyWith(
              color: _textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Registra tu primera parcela para recibir diagnosticos precisos.',
              style: AppTypography.etiquetaSm.copyWith(color: _textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _openAddParcel(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmAmber,
                foregroundColor: const Color(0xFF4A2800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              color: _textSecondary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.etiquetaSm.copyWith(color: _textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<ParcelBloc>().add(const ParcelLoadRequested()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

  Widget _statusChip(String label, Color bg, Color text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: text),
          const SizedBox(width: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _chipBlueBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.analytics_outlined, size: 10, color: _chipBlueText),
          const SizedBox(width: 3),
          Text(
            '$count ${count == 1 ? 'diagnóstico' : 'diagnósticos'}',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _chipBlueText,
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
          chipBg: _chipAlertBg,
          chipText: _chipAlertText,
          icon: Icons.warning_amber_rounded,
        );
      case 'Seguimiento':
        return _StatusColors(
          border: AppColors.warmAmber,
          chipBg: _chipFollowBg,
          chipText: _chipFollowText,
          icon: Icons.visibility_outlined,
        );
      case 'Saludable':
        return _StatusColors(
          border: AppColors.forestGreen,
          chipBg: _chipGreenBg,
          chipText: _chipGreenText,
          icon: Icons.check_circle_outline_rounded,
        );
      default: // 'Sin diagnostico' y cualquier otro
        return _StatusColors(
          border: _borderLight,
          chipBg: const Color(0xFFF0F2F5),
          chipText: _textSecondary,
          icon: Icons.radio_button_unchecked_outlined,
        );
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1)
      return 'hace ${diff.inDays} dia${diff.inDays > 1 ? 's' : ''}';
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
