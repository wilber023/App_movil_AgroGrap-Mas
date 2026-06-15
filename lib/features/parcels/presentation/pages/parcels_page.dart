import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'add_parcel_page.dart';
import 'parcel_detail_page.dart';

// =============================================================================
// AgroGraph-MAS -- Mis Parcelas (lista principal)
// =============================================================================
// Replica pixel-perfect del spec de diseno.
// Colores clave: primary #2D6A4F, accent #F4A261, danger #E76F51,
//   background #F8FAF5, cards blancas sin sombras, 0.5px borde.
// =============================================================================

// Constantes de color inline que no existen en AppColors.
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
const Color _addGreen = Color(0xFF52B788);
const Color _addBorder = Color(0xFFA8C5B0);

/// Modelo de datos local para cada parcela del listado.
class _ParcelData {
  final String name;
  final String crop;
  final String area;
  final Color borderColor;
  final Color statusBg;
  final Color statusText;
  final IconData statusIcon;
  final String statusLabel;
  final String diagnosisAge;
  final String stageName;
  final double stageProgress; // 0.0 - 1.0
  final int stageIndex; // 0-3 de 4 etapas

  const _ParcelData({
    required this.name,
    required this.crop,
    required this.area,
    required this.borderColor,
    required this.statusBg,
    required this.statusText,
    required this.statusIcon,
    required this.statusLabel,
    required this.diagnosisAge,
    required this.stageName,
    required this.stageProgress,
    required this.stageIndex,
  });
}

class ParcelsPage extends StatelessWidget {
  const ParcelsPage({super.key});

  static const List<String> _stages = [
    'Siembra',
    'Vegetativo',
    'Floracion',
    'Cosecha',
  ];

  static const List<_ParcelData> _parcels = [
    _ParcelData(
      name: 'Milpa Norte',
      crop: 'Maiz',
      area: '2.5 ha',
      borderColor: AppColors.burntOrange, // #E76F51
      statusBg: _chipAlertBg,
      statusText: _chipAlertText,
      statusIcon: Icons.warning_amber_rounded,
      statusLabel: 'Alerta',
      diagnosisAge: 'hace 1 dia',
      stageName: 'Floracion',
      stageProgress: 0.60,
      stageIndex: 2,
    ),
    _ParcelData(
      name: 'Huerta Baja',
      crop: 'Jitomate',
      area: '1 ha',
      borderColor: AppColors.warmAmber, // #F4A261
      statusBg: _chipFollowBg,
      statusText: _chipFollowText,
      statusIcon: Icons.visibility_outlined,
      statusLabel: 'Seguimiento',
      diagnosisAge: 'hace 5 dias',
      stageName: 'Vegetativo',
      stageProgress: 0.45,
      stageIndex: 1,
    ),
    _ParcelData(
      name: 'Terreno Sur',
      crop: 'Frijol',
      area: '3 ha',
      borderColor: AppColors.forestGreen, // #2D6A4F
      statusBg: _chipGreenBg,
      statusText: _chipGreenText,
      statusIcon: Icons.check_circle_outline_rounded,
      statusLabel: 'Saludable',
      diagnosisAge: 'hace 12 dias',
      stageName: 'Llenado de grano',
      stageProgress: 0.80,
      stageIndex: 3,
    ),
  ];

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
      body: _parcels.isEmpty
          ? _buildEmptyState(context)
          : _buildParcelList(context),
    );
  }

  void _openAddParcel(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddParcelPage()),
    );
  }

  // ---------------------------------------------------------------------------
  // Lista con parcelas
  // ---------------------------------------------------------------------------
  Widget _buildParcelList(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de busqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 12),
          // Tarjetas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (int i = 0; i < _parcels.length; i++) ...[
                  _buildParcelCard(context, _parcels[i]),
                  if (i < _parcels.length - 1) const SizedBox(height: 10),
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
  // Barra de busqueda
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar() {
    return SizedBox(
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderLight.withValues(alpha: 0.4), width: 0.5),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Buscar parcela...',
            hintStyle: AppTypography.etiquetaSm.copyWith(
              color: _borderLight,
              fontSize: 13,
            ),
            prefixIcon: const Icon(Icons.search_outlined, color: _textSecondary, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tarjeta de parcela
  // ---------------------------------------------------------------------------
  Widget _buildParcelCard(BuildContext context, _ParcelData p) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ParcelDetailPage(parcelName: p.name)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: p.borderColor, width: 4),
            top: BorderSide(color: _borderLight.withValues(alpha: 0.3), width: 0.5),
            right: BorderSide(color: _borderLight.withValues(alpha: 0.3), width: 0.5),
            bottom: BorderSide(color: _borderLight.withValues(alpha: 0.3), width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: nombre, cultivo, hectareas, menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: AppTypography.labelMd.copyWith(
                          color: _textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _chip(p.crop, _chipGreenBg, _chipGreenText),
                          const SizedBox(width: 6),
                          Text(
                            p.area,
                            style: AppTypography.etiquetaSm.copyWith(
                              color: _textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildThreeDotMenu(context, p.name),
              ],
            ),
            const SizedBox(height: 6),
            // Row 2: status chip + diagnostico
            Row(
              children: [
                _statusChip(p.statusLabel, p.statusBg, p.statusText, p.statusIcon),
                const SizedBox(width: 6),
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
                  'Diagnostico ${p.diagnosisAge}',
                  style: AppTypography.etiquetaSm.copyWith(
                    color: _textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Row 3: barra fenologica
            _buildPhenologicalBar(p),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Menu de tres puntos
  // ---------------------------------------------------------------------------
  Widget _buildThreeDotMenu(BuildContext context, String parcelName) {
    return SizedBox(
      width: 48,
      height: 48,
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_outlined, color: _borderLight, size: 16),
        onSelected: (value) {
          if (value == 'detalle') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ParcelDetailPage(parcelName: parcelName),
              ),
            );
          }
          if (value == 'diagnostico') {
            // Redirigir a diagnostico (tab 1 del MainShell)
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'detalle', child: Text('Ver detalle')),
          const PopupMenuItem(value: 'diagnostico', child: Text('Nuevo diagnostico')),
          const PopupMenuItem(value: 'editar', child: Text('Editar parcela')),
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

  // ---------------------------------------------------------------------------
  // Barra fenologica con puntos de etapa
  // ---------------------------------------------------------------------------
  Widget _buildPhenologicalBar(_ParcelData p) {
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
        // Barra de progreso
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: p.stageProgress,
              backgroundColor: _trackGrey,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Puntos de etapa
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_stages.length, (i) {
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
                  _stages[i],
                  style: TextStyle(
                    fontFamily: 'Inter',
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
  // Boton dashed "Agregar nueva parcela"
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
  // Estado vacio
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
            child: const Icon(Icons.local_florist_outlined, color: _addGreen, size: 36),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  // Chips reutilizables
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
        style: TextStyle(
          fontFamily: 'Inter',
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
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Painter para borde discontinuo (dashed)
// =============================================================================
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  static const double _dashWidth = 6;
  static const double _dashGap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

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
