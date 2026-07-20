import 'package:flutter/material.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../../agricultor/diagnosis/domain/entities/llm_response_entity.dart';
import '../../../agenda/agenda.dart';
import '../../../agenda/domain/usecases/generate_agenda_usecase.dart';
import '../../../agenda/domain/usecases/get_agenda_overview_usecase.dart';

/// Muestra el tratamiento/prevención recomendados por el asistente IA (LLM),
/// en lenguaje sencillo para el aprendiz. Sin datos económicos ni de producto
/// fabricados: si el LLM aún no respondió, se informa en vez de inventar cifras.
class AprendizRecommendedActionPage extends StatelessWidget {
  final String diseaseName;
  final String cropName;
  final LlmResponseEntity? llmResponse;

  const AprendizRecommendedActionPage({
    super.key,
    required this.diseaseName,
    required this.cropName,
    this.llmResponse,
  });

  @override
  Widget build(BuildContext context) {
    final r = llmResponse;

    return Scaffold(
      backgroundColor: AppColors.aMint,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              height: 56,
              color: AppColors.aPrimaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.aOnPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Qué hacer ahora',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.aOnPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xgiantPlus),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxlPlus),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumb
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xxlPlus),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant),
                          children: [
                            const TextSpan(
                              text: 'Sobre: ',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.aOnSurface),
                            ),
                            TextSpan(text: '$diseaseName · $cropName'),
                          ],
                        ),
                      ),
                    ),

                    if (r == null)
                      _InfoCard(
                        icon: Icons.hourglass_empty_rounded,
                        title: 'Aún no hay una recomendación disponible',
                        body: 'Vuelve a la pantalla de resultado y espera a que '
                            'el asistente IA termine de generar la explicación '
                            'para ver aquí el tratamiento sugerido.',
                      )
                    else ...[
                      if (r.tratamiento.isNotEmpty)
                        _ActionCard(
                          icon: Icons.healing_outlined,
                          label: 'QUÉ HACER',
                          content: r.tratamiento,
                        ),
                      if (r.prevencion.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _ActionCard(
                          icon: Icons.shield_outlined,
                          label: 'CÓMO PREVENIRLO',
                          content: r.prevencion,
                        ),
                      ],
                      if (r.tratamiento.isEmpty && r.prevencion.isEmpty)
                        _InfoCard(
                          icon: Icons.info_outline,
                          title: 'Sin recomendación específica',
                          body: 'El asistente IA no encontró un tratamiento '
                              'específico para este caso. Consulta a tu instructor.',
                        ),
                    ],

                    const SizedBox(height: AppSpacing.giant),

                    // CTA buttons
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: r == null ? null : () => _addToAgenda(context, r),
                        icon: const Icon(Icons.event_available, color: AppColors.aOnPrimary),
                        label: const Text(
                          'Agregar a mi agenda',
                          style: TextStyle(color: AppColors.aOnPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.aOrange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Volver al resultado',
                          style: TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.colossal),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToAgenda(BuildContext context, LlmResponseEntity r) async {
    final overviewResult = await sl<GetAgendaOverviewUseCase>()(const NoParams());
    final hasActivePlan = overviewResult.fold(
      (_) => false,
      (overview) => overview.activities.isNotEmpty,
    );

    if (hasActivePlan && context.mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reemplazar plan actual'),
          content: const Text(
            'Ya tienes un plan de tratamiento activo en tu agenda. Agregar '
            'este te lo va a reemplazar por completo. ¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.aOrange),
              child: const Text('Reemplazar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.aOrange),
      ),
    );

    final result = await sl<GenerateAgendaUseCase>()(GenerateAgendaParams(
      cultivo: cropName,
      enfermedad: diseaseName,
      tratamiento: r.tratamiento,
      prevencion: r.prevencion.isNotEmpty ? r.prevencion : null,
    ));

    if (!context.mounted) return;
    Navigator.pop(context); // cierra el dialogo de carga

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failure is NetworkFailure
                ? 'Necesitas conexión a internet para generar tu plan de tratamiento.'
                : failure.message,
          ),
        ),
      ),
      (_) => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AprendizAgendaPage()),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String content;

  const _ActionCard({required this.icon, required this.label, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        border: Border.all(color: AppColors.aOutlineVariant),
        boxShadow: [
          BoxShadow(color: AppColors.aOnSurface.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: const BoxDecoration(color: AppColors.aMint, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.aSecondary, size: 16),
              ),
              const SizedBox(width: AppSpacing.lg),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.aSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            content,
            style: const TextStyle(fontSize: 15, color: AppColors.aOnSurface, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        border: Border.all(color: AppColors.aOutlineVariant),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.aOnSurfaceVariant, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.aOnSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            style: const TextStyle(fontSize: 13, color: AppColors.aOnSurfaceVariant, height: 1.4),
          ),
        ],
      ),
    );
  }
}
