import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/services/cnn_engine/cnn_result.dart';
import '../../domain/entities/diagnosis_entity.dart';

// =============================================================================
// AgroGraph-MAS -- Resultado del Diagnóstico CNN
// Muestra: cultivo, enfermedad, confianza, top-K predicciones
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
          'Resultado del diagnóstico',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            _buildHeroCard(),
            if (diagnosis.topK.length > 1) ...[
              const SizedBox(height: 8),
              _buildTopKSection(),
            ],
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
                          _pill(
                              diagnosis.parcelName!, _chipBlueBg, _chipBlueText),
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
              widthFactor: diagnosis.confidence.clamp(0.0, 1.0),
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
            'Modelo local · EfficientNetB4 · sin API externa',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: Color(0xFFADB5BD),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: diagnosis.imagePath != null &&
                      File(diagnosis.imagePath!).existsSync()
                  ? Image.file(
                      File(diagnosis.imagePath!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: const Color(0xFFD8EAD0),
                      child: const Icon(
                        Icons.eco_outlined,
                        color: AppColors.forestGreen,
                        size: 48,
                      ),
                    ),
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

  Widget _buildTopKSection() {
    final others = diagnosis.topK.skip(1).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
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
            const Text(
              'Otras predicciones del modelo',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...others.map((p) => _buildTopKRow(p)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopKRow(TopKPrediction p) {
    final pct = (p.confidence * 100).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${p.cropName} · ${p.diseaseName}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: _textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _trackGrey,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: p.confidence.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: _textSecondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
