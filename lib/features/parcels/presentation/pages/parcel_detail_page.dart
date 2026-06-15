import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

// =============================================================================
// AgroGraph-MAS -- Detalle de Parcela
// =============================================================================
// Vista completa con hero card, acciones rapidas, alerta activa, tratamiento
// activo y datos registrados. Sin sombras, 0.5px bordes, offline-first.
// =============================================================================

const Color _bg = Color(0xFFF8FAF5);
const Color _textPrimary = Color(0xFF1B2D27);
const Color _textSecondary = Color(0xFF6B8F71);
const Color _hintColor = Color(0xFFADB5BD);
const Color _chipGreenBg = Color(0xFFEAF3DE);
const Color _chipGreenText = Color(0xFF27500A);
const Color _chipAlertBg = Color(0xFFFDECEA);
const Color _chipAlertText = Color(0xFFA32D2D);
const Color _chipBlueBg = Color(0xFFE6F1FB);
const Color _chipBlueText = Color(0xFF0C447C);
const Color _trackGrey = Color(0xFFE2EBE6);
const Color _alertBorder = Color(0xFFF09595);

class ParcelDetailPage extends StatelessWidget {
  final String parcelName;

  const ParcelDetailPage({super.key, required this.parcelName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          parcelName,
          style: AppTypography.labelMd.copyWith(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroCard(),
            const SizedBox(height: 8),
            _buildQuickActions(),
            const SizedBox(height: 8),
            _buildActiveAlert(),
            const SizedBox(height: 8),
            _buildTreatmentCard(),
            const SizedBox(height: 8),
            _buildParcelDataCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hero Card
  // ---------------------------------------------------------------------------
  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _hintColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Nombre + chips + status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Milpa Norte',
                      style: AppTypography.labelMd.copyWith(
                        color: _textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _pill('Maiz', _chipGreenBg, _chipGreenText),
                        _pill('2.5 ha', _hintColor.withValues(alpha: 0.15), _textSecondary),
                        _pill('Floracion', _chipBlueBg, _chipBlueText),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tuxtla Gutierrez, Chiapas',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _pill('Alerta', _chipAlertBg, _chipAlertText),
            ],
          ),
          const SizedBox(height: 12),
          // Barra fenologica
          _buildDetailPhenologicalBar(),
        ],
      ),
    );
  }

  Widget _buildDetailPhenologicalBar() {
    const stages = ['Siembra', 'Vegetativo', 'Floracion', 'Cosecha'];
    const currentStageIndex = 2; // Floracion
    const progress = 0.60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ciclo \u00B7 Siembra: 15 mar 2026',
              style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: _textSecondary),
            ),
            Text(
              'Cosecha estimada: 15 ago 2026',
              style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: _hintColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _trackGrey,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stages.length, (i) {
            final isCurrent = i == currentStageIndex;
            final reached = i <= currentStageIndex;
            return Column(
              children: [
                Container(
                  width: isCurrent ? 10 : 6,
                  height: isCurrent ? 10 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reached ? AppColors.forestGreen : _trackGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCurrent ? '${stages[i]}\u25CF' : stages[i],
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 8,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
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
  // Acciones rapidas
  // ---------------------------------------------------------------------------
  Widget _buildQuickActions() {
    return Row(
      children: [
        _actionCard('Diagnosticar', Icons.camera_alt_outlined, AppColors.forestGreen),
        const SizedBox(width: 8),
        _actionCard('Historial', Icons.access_time_outlined, _hintColor),
      ],
    );
  }

  Widget _actionCard(String label, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _hintColor.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Alerta activa
  // ---------------------------------------------------------------------------
  Widget _buildActiveAlert() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _chipAlertBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _alertBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.burntOrange, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tizón tardío \u00B7 91% confianza',
                  style: AppTypography.labelMd.copyWith(
                    color: _chipAlertText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _pill('Urgente', AppColors.burntOrange, Colors.white),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Intervención recomendada en las próximas 24 horas.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: _chipAlertText,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burntOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Ver diagnóstico',
                style: TextStyle(fontFamily: 'Inter', fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tratamiento activo
  // ---------------------------------------------------------------------------
  Widget _buildTreatmentCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _hintColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tratamiento activo',
                style: AppTypography.etiquetaSm.copyWith(
                  color: _textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _pill('Paso 1 de 3', AppColors.warmAmber.withValues(alpha: 0.2), AppColors.warmAmber),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: const SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: 0.33,
                backgroundColor: _trackGrey,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: AppColors.warmAmber, size: 12),
              const SizedBox(width: 6),
              Text(
                'Próximo: Segunda aplicación \u00B7 10 jun',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Datos registrados
  // ---------------------------------------------------------------------------
  Widget _buildParcelDataCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _hintColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Datos registrados',
                style: AppTypography.etiquetaSm.copyWith(
                  color: _textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.edit_outlined, color: _textSecondary, size: 14),
            ],
          ),
          const SizedBox(height: 8),
          _dataRow('Tipo de terreno', 'Pendiente ligera', null),
          _divider(),
          _dataRow('Condición del suelo', 'Buen drenaje', null),
          _divider(),
          _dataRow('Maleza predominante', 'Pastos', null),
          _divider(),
          _dataRow('Siembra', '15 mar 2026', null),
          _divider(),
          _dataRow('Etapa actual', 'Floración', null),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFADB5BD), size: 12),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Estos datos ayudan a contextualizar diagnósticos y futuras recomendaciones.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: Color(0xFFADB5BD),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value, Color? valueColor) {
    return SizedBox(
      height: 34,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: _textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: valueColor ?? _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: _hintColor.withValues(alpha: 0.2),
    );
  }

  // ---------------------------------------------------------------------------
  // Pill reutilizable
  // ---------------------------------------------------------------------------
  Widget _pill(String label, Color bg, Color text) {
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
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: text,
        ),
      ),
    );
  }
}
