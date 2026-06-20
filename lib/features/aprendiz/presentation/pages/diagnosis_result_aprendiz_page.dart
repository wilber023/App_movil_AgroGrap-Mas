import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../diagnosis/domain/entities/diagnosis_entity.dart';
import '../../domain/entities/crop_activity_entity.dart';
import '../bloc/diagnosis_result_aprendiz_cubit.dart';
import 'aprendiz_main_shell.dart';

class DiagnosisResultAprendizPage extends StatelessWidget {
  final DiagnosisEntity diagnosis;
  final String activityId;

  const DiagnosisResultAprendizPage({
    super.key, 
    required this.diagnosis,
    required this.activityId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DiagnosisResultAprendizCubit>(),
      child: _DiagnosisResultAprendizView(diagnosis: diagnosis, activityId: activityId),
    );
  }
}

class _DiagnosisResultAprendizView extends StatelessWidget {
  final DiagnosisEntity diagnosis;
  final String activityId;

  const _DiagnosisResultAprendizView({
    required this.diagnosis,
    required this.activityId,
  });

  @override
  Widget build(BuildContext context) {
    final isHealthy = diagnosis.severity.toLowerCase() == 'saludable';
    final primaryColor = isHealthy ? AppColors.forestGreen : AppColors.error;

    return BlocListener<DiagnosisResultAprendizCubit, DiagnosisResultAprendizState>(
      listener: (context, state) {
        if (state is AgendaUpdated) {
          _showAgendaUpdatedModal(context, state.newActivities);
        } else if (state is DiagnosisResultError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message, style: const TextStyle(color: Colors.white))),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
        title: const Text('Resultado de Diagnóstico'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen
            if (diagnosis.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  diagnosis.imagePath!,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: AppColors.surfaceContainerHigh,
                    child: const Icon(Icons.broken_image_rounded, size: 48),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Título Simple
            Text(
              isHealthy ? '¡Tu cultivo está sano!' : diagnosis.diseaseName,
              style: AppTypography.tituloLg.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Barra de Confianza
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Precisión del modelo: ${(diagnosis.confidence * 100).toStringAsFixed(1)}%',
                  style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(height: 32),

            if (!isHealthy) ...[
              // Qué tiene
              _buildSectionTitle('¿Qué tiene?'),
              Text(
                diagnosis.description,
                style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 24),

              // Qué hacer hoy
              _buildSectionTitle('¿Qué hacer hoy?'),
              ...diagnosis.recommendationsWhatToDo.map((rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.forestGreen, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(rec, style: AppTypography.bodyMd)),
                      ],
                    ),
                  )),
              const SizedBox(height: 24),

              // Qué pasa si no actúas
              _buildSectionTitle('¿Qué pasa si no actúas?'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                ),
                child: Text(
                  diagnosis.recommendationsNoAction,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 24),

              // Prioridad
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warmAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: AppColors.warmAmber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Prioridad: Alta\nTiempo recomendado: Hoy mismo',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.warmAmber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Botón Agregar a agenda
              BlocBuilder<DiagnosisResultAprendizCubit, DiagnosisResultAprendizState>(
                builder: (context, state) {
                  final isLoading = state is DiagnosisResultLoading;
                  return ElevatedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () {
                            context.read<DiagnosisResultAprendizCubit>().acceptAction(activityId);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.calendar_today_rounded, color: Colors.white),
                    label: Text(
                      isLoading ? 'Procesando...' : 'Agregar a mi agenda',
                      style: AppTypography.labelMd.copyWith(color: Colors.white, fontSize: 16),
                    ),
                  );
                },
              ),
            ] else ...[
              // Variante Positiva
              Text(
                'No se detectaron signos de enfermedad en la foto tomada. Sigue con tu plan regular.',
                style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Continuar',
                  style: AppTypography.labelMd.copyWith(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: AppTypography.headlineMd.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAgendaUpdatedModal(BuildContext context, List<CropActivityEntity> activities) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primaryContainer,
                child: const Icon(Icons.check_circle_rounded, size: 32, color: AppColors.forestGreen),
              ),
              const SizedBox(height: 16),
              Text(
                '¡Listo! Tu agenda fue actualizada',
                style: AppTypography.tituloLg.copyWith(color: AppColors.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Se crearon ${activities.length} actividades automáticamente:',
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Mini línea de tiempo
              ...activities.map((activity) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.forestGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        activity.title,
                        style: AppTypography.etiquetaBold.copyWith(color: AppColors.onSurface),
                      ),
                    ),
                    Text(
                      '${activity.scheduledDate.day}/${activity.scheduledDate.month}/${activity.scheduledDate.year}',
                      style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, size: 20, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Recibirás recordatorios antes de cada actividad.',
                        style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Agenda (tab index 3 in AprendizMainShell)
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const AprendizMainShell(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Ver mi agenda →'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
