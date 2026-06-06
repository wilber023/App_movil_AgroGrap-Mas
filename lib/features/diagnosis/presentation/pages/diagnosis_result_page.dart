import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/shared_components.dart';
import '../../domain/entities/diagnosis_entity.dart';

// Pantalla de resultado del diagnostico (Stitch: "Resultado del Diagnostico")
// Imagen con pill de severidad, datos del modelo CNN, recomendaciones, impacto economico.

class DiagnosisResultPage extends StatelessWidget {
  final DiagnosisEntity diagnosis;
  const DiagnosisResultPage({super.key, required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen del cultivo afectado
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
              ),
              child: const Icon(
                Icons.local_florist_rounded,
                size: 80,
                color: AppColors.forestGreen,
              ),
            ),
            // Gradiente inferior
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                  ),
                ),
              ),
            ),
            // Pill de severidad
            Positioned(
              top: 100,
              right: 16,
              child: StatusPill.severity(diagnosis.severity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre de enfermedad y nombre cientifico
          _buildDiseaseHeader(),
          const SizedBox(height: 20),
          // Confianza del modelo CNN
          _buildConfidenceCard(),
          const SizedBox(height: 16),
          // Descripcion
          _buildDescriptionCard(),
          const SizedBox(height: 16),
          // Sintomas
          if (diagnosis.symptoms.isNotEmpty) ...[
            _buildSymptomsCard(),
            const SizedBox(height: 16),
          ],
          // Recomendaciones
          if (diagnosis.recommendations.isNotEmpty) ...[
            _buildRecommendationsCard(),
            const SizedBox(height: 16),
          ],
          // Impacto economico
          _buildEconomicImpact(),
          const SizedBox(height: 24),
          // Botones de accion
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildDiseaseHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          diagnosis.diseaseName,
          style: AppTypography.tituloLg.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          'Cultivo: ${diagnosis.cropName}',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceCard() {
    final percentage = (diagnosis.confidence * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.model_training_rounded,
                      size: 20, color: AppColors.forestGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Confianza del Modelo CNN',
                    style: AppTypography.labelMd
                        .copyWith(color: AppColors.onSurface),
                  ),
                ],
              ),
              Text(
                '$percentage%',
                style: AppTypography.headlineMd.copyWith(
                  color: percentage >= 70
                      ? AppColors.forestGreen
                      : AppColors.warmAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppProgressBar(
            value: diagnosis.confidence,
            color: percentage >= 70
                ? AppColors.forestGreen
                : AppColors.warmAmber,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return InfoCard(
      title: 'Descripcion',
      subtitle: diagnosis.description,
      icon: Icons.info_outline_rounded,
      iconColor: AppColors.tertiary,
    );
  }

  Widget _buildSymptomsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_outlined,
                  size: 20, color: AppColors.warmAmber),
              const SizedBox(width: 8),
              Text(
                'Sintomas Identificados',
                style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...diagnosis.symptoms.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 6,
                        color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s,
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.onSurfaceVariant),
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

  Widget _buildRecommendationsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusHealthyBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded,
                  size: 20, color: AppColors.forestGreen),
              const SizedBox(width: 8),
              Text(
                'Recomendaciones',
                style: AppTypography.labelMd.copyWith(color: AppColors.forestGreen),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...diagnosis.recommendations.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.forestGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: AppTypography.etiquetaSm.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.onSurface),
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

  Widget _buildEconomicImpact() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusAtRiskBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.burntOrange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.burntOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.attach_money_rounded,
                size: 22, color: AppColors.burntOrange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Impacto Economico Estimado',
                  style:
                      AppTypography.labelMd.copyWith(color: AppColors.burntOrange),
                ),
                const SizedBox(height: 2),
                Text(
                  'Perdida potencial sin tratamiento',
                  style: AppTypography.etiquetaSm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.calendar_month_rounded, size: 20),
            label: const Text('Aceptar calendario de tratamiento'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.bar_chart_rounded, size: 20),
            label: const Text('Ver analisis economico'),
          ),
        ),
      ],
    );
  }
}
