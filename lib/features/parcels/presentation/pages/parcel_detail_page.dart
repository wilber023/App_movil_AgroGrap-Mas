import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/parcel_entity.dart';

// =============================================================================
// AgroGraph-MAS -- Detalle de Parcela
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

class ParcelDetailPage extends StatelessWidget {
  final ParcelEntity parcel;

  const ParcelDetailPage({super.key, required this.parcel});

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
          parcel.name,
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
            _buildParcelDataCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hero Card con datos reales
  // ---------------------------------------------------------------------------

  Widget _buildHeroCard() {
    final statusBg = _statusBg(parcel.status);
    final statusText = _statusText(parcel.status);

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcel.name,
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
                        _pill(parcel.cropName, _chipGreenBg, _chipGreenText),
                        _pill(
                          '${parcel.areaSize.toStringAsFixed(1)} ${parcel.areaUnit}',
                          _hintColor.withValues(alpha: 0.15),
                          _textSecondary,
                        ),
                        _pill(parcel.stageName, _chipBlueBg, _chipBlueText),
                      ],
                    ),
                    if (parcel.region.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        parcel.region,
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: _textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              if (parcel.status != 'Sin diagnostico')
                _pill(parcel.status, statusBg, statusText),
            ],
          ),
          const SizedBox(height: 12),
          _buildPhenologicalBar(),
        ],
      ),
    );
  }

  Widget _buildPhenologicalBar() {
    const stages = ['Siembra', 'Vegetativo', 'Floracion', 'Cosecha'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              parcel.fechaSiembra != null
                  ? 'Ciclo · Siembra: ${_formatDate(parcel.fechaSiembra!)}'
                  : 'Ciclo fenológico',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: _textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: parcel.stageProgress,
              backgroundColor: _trackGrey,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stages.length, (i) {
            final isCurrent = i == parcel.stageIndex;
            final reached = i <= parcel.stageIndex;
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
                  isCurrent ? '${stages[i]}●' : stages[i],
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
  // Acciones rápidas
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
            Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: _textPrimary)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Datos registrados reales
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
                style: AppTypography.etiquetaSm.copyWith(color: _textPrimary, fontWeight: FontWeight.w500),
              ),
              const Icon(Icons.edit_outlined, color: _textSecondary, size: 14),
            ],
          ),
          const SizedBox(height: 8),
          _dataRow('Cultivo', parcel.cropName),
          _divider(),
          _dataRow('Superficie', '${parcel.areaSize.toStringAsFixed(1)} ${parcel.areaUnit}'),
          if (parcel.region.isNotEmpty) ...[
            _divider(),
            _dataRow('Región', parcel.region),
          ],
          if (parcel.fechaSiembra != null) ...[
            _divider(),
            _dataRow('Fecha de siembra', _formatDate(parcel.fechaSiembra!)),
          ],
          _divider(),
          _dataRow('Etapa actual', parcel.stageName),
          _divider(),
          _dataRow('Estado de salud', parcel.status),
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
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFFADB5BD)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _dataRow(String label, String value) {
    return SizedBox(
      height: 34,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: _textSecondary)),
          Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: _textPrimary)),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, thickness: 0.5, color: _hintColor.withValues(alpha: 0.2));

  Widget _pill(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(
        label,
        style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: text),
      ),
    );
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Alerta':
        return _chipAlertBg;
      case 'Seguimiento':
        return const Color(0xFFFFF3E0);
      default:
        return _chipGreenBg;
    }
  }

  Color _statusText(String status) {
    switch (status) {
      case 'Alerta':
        return _chipAlertText;
      case 'Seguimiento':
        return const Color(0xFF7B4A10);
      default:
        return _chipGreenText;
    }
  }

  String _formatDate(DateTime dt) {
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
