import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/diagnosis_entity.dart';

// =============================================================================
// AgroGraph-MAS -- Resultado del Diagnostico
// =============================================================================
// Pantalla inmutable que muestra el resultado de la inferencia.
// =============================================================================

const Color _bg = Color(0xFFF8FAF5);
const Color _textPrimary = Color(0xFF1B2D27);
const Color _textSecondary = Color(0xFF6B8F71);
const Color _trackGrey = Color(0xFFE2EBE6);

const Color _chipGreenBg = Color(0xFFEAF3DE);
const Color _chipGreenText = Color(0xFF27500A);
const Color _chipBlueBg = Color(0xFFE6F1FB);
const Color _chipBlueText = Color(0xFF0C447C);

const Color _badgeAlertBg = Color(0xFFFDECEA);
const Color _badgeAlertText = Color(0xFFA32D2D);
const Color _badgeWarnBg = Color(0xFFFFF3E0);
const Color _badgeWarnText = Color(0xFF7B4A10);

const Color _ctaAmberBg = Color(0xFFF4A261);
const Color _ctaAmberText = Color(0xFF4A2800);

class DiagnosisResultPage extends StatelessWidget {
  final DiagnosisEntity diagnosis;

  const DiagnosisResultPage({super.key, required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2D27),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Resultado del diagnostico',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            _buildHeroCard(),
            const SizedBox(height: 8),
            _buildRecommendations(),
            const SizedBox(height: 12),
            _buildCTAs(),
            const SizedBox(height: 8),
            _buildShareLink(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _trackGrey, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diagnosis.diseaseName,
                      style: AppTypography.tituloMd.copyWith(
                        color: _textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      diagnosis.scientificName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: _textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _pill(diagnosis.cropName, _chipGreenBg, _chipGreenText),
                        if (diagnosis.parcelName != null) ...[
                          const SizedBox(width: 6),
                          _pill(diagnosis.parcelName!, _chipBlueBg, _chipBlueText),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
              _buildSeverityBadge(diagnosis.severity),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Confianza del modelo CNN',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: _textSecondary,
                ),
              ),
              Text(
                '${(diagnosis.confidence * 100).toInt()}%',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.forestGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _trackGrey,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: diagnosis.confidence,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.forestGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Modelo local \u00B7 EfficientNetB4 \u00B7 sin API externa',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: Color(0xFFADB5BD),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 140,
              width: double.infinity,
              color: const Color(0xFFD8EAD0),
              child: diagnosis.imagePath != null
                  ? const Icon(Icons.image, color: AppColors.forestGreen, size: 48) // Placeholder instead of file loading to avoid dart:io issues directly
                  : const Icon(Icons.eco_outlined, color: AppColors.forestGreen, size: 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          color: textCol,
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color bg = _badgeAlertBg;
    Color tc = _badgeAlertText;
    if (severity == 'Moderada') {
      bg = _badgeWarnBg;
      tc = _badgeWarnText;
    } else if (severity == 'Leve' || severity == 'Saludable') {
      bg = _chipGreenBg;
      tc = _chipGreenText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        severity,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: tc,
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          if (diagnosis.recommendationsWhatIs.isNotEmpty)
            _infoCard(
              Icons.biotech_outlined,
              AppColors.forestGreen,
              '\u00BFQue tiene?',
              _textPrimary,
              diagnosis.recommendationsWhatIs.join(' '),
            ),
          const SizedBox(height: 8),
          if (diagnosis.recommendationsWhatToDo.isNotEmpty)
            _infoCard(
              Icons.medication_outlined,
              const Color(0xFF52B788),
              '\u00BFQue hacer hoy?',
              _textPrimary,
              diagnosis.recommendationsWhatToDo.join(' '),
            ),
          const SizedBox(height: 8),
          if (diagnosis.recommendationsNoAction.isNotEmpty)
            _dangerCard(diagnosis.recommendationsNoAction),
        ],
      ),
    );
  }

  Widget _infoCard(
      IconData icon, Color iconColor, String title, Color titleColor, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _trackGrey, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.labelMd.copyWith(
                  color: titleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: _textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dangerCard(String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _badgeWarnBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warmAmber, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFE76F51), size: 16),
              const SizedBox(width: 8),
              Text(
                '\u00BFQue pasa si no actuas?',
                style: AppTypography.labelMd.copyWith(
                  color: _badgeWarnText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: _badgeWarnText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _ctaAmberBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.trending_up, color: _ctaAmberText, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Ver analisis economico \u2192',
                    style: AppTypography.labelMd.copyWith(
                      color: _ctaAmberText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Aceptar calendario de tratamiento',
                    style: AppTypography.labelMd.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareLink() {
    return Center(
      child: GestureDetector(
        onTap: () {},
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.share_outlined, color: _textSecondary, size: 12),
            SizedBox(width: 4),
            Text(
              'Compartir con mi gestor',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
