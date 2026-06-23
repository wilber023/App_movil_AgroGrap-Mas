import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../diagnosis/domain/entities/diagnosis_entity.dart';
import '../../domain/entities/crop_activity_entity.dart';
import '../bloc/diagnosis_result_aprendiz_cubit.dart';
import 'aprendiz_main_shell.dart';
import 'aprendiz_recommended_action_page.dart';

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
    final isHealthy = diagnosis.statusLabel == 'Saludable';

    return BlocListener<DiagnosisResultAprendizCubit, DiagnosisResultAprendizState>(
      listener: (context, state) {
        if (state is AgendaUpdated) {
          _showAgendaUpdatedModal(context, state.newActivities);
        } else if (state is DiagnosisResultError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: const TextStyle(color: Colors.white)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.aSurface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // TopAppBar
              Container(
                height: 56,
                color: AppColors.aPrimaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Resultado del análisis',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Analyzed image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: diagnosis.imagePath != null &&
                                File(diagnosis.imagePath!).existsSync()
                            ? Image.file(
                                File(diagnosis.imagePath!),
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : _ImagePlaceholder(),
                      ),

                      const SizedBox(height: 20),

                      // Plant ID section
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.aSurfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.aOutlineVariant),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.aMint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.eco_outlined, color: AppColors.aSecondary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Planta identificada',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.aOnSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.05,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    diagnosis.cropName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.aOnSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.aSecondaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${(diagnosis.confidence * 100).toStringAsFixed(0)}% confianza',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.aOnSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (isHealthy) ...[
                        // Healthy variant
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.aMint,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.aSecondaryContainer),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Container(
                                width: 60, height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.aSecondaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle_outline, color: AppColors.aSecondary, size: 32),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '¡Tu cultivo está sano!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.aSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'No se detectaron signos de enfermedad. Sigue con tu plan regular.',
                                style: TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant, height: 1.5),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.aOrange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Continuar',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Disease detected variant
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.aDiseaseCardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.aDiseaseCardBorder),
                          ),
                          child: Stack(
                            children: [
                              // Red left accent
                              Positioned(
                                left: 0, top: 0, bottom: 0,
                                child: Container(
                                  width: 4,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.warning_rounded, color: AppColors.error, size: 18),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'ENFERMEDAD DETECTADA',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.05,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      diagnosis.diseaseName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.aDiseaseCardText,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Cultivo: ${diagnosis.cropName}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.aOnSurfaceVariant,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Confianza del modelo
                        const Text(
                          '¿QUÉ HACER AHORA?',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.aOnSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.05,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.aSurfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.aOutlineVariant),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20, height: 20,
                                margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.aSecondaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    '1',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.aSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Revisa la hoja o fruto afectado y compara con las guías de tu instructor.',
                                  style: TextStyle(fontSize: 14, color: AppColors.aOnSurface, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Aviso de riesgo genérico
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.aWarningBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.aWarningBorder),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_outline, color: AppColors.aOrange, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Sin atención oportuna, la enfermedad puede propagarse al resto del cultivo.',
                                  style: TextStyle(fontSize: 13, color: AppColors.aWarningText, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // CTA: Ver acción recomendada
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AprendizRecommendedActionPage(
                                    diseaseName: diagnosis.diseaseName,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward, color: Colors.white),
                            label: const Text(
                              'Ver acción recomendada',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.aOrange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Secondary: Guardar en historial
                        BlocBuilder<DiagnosisResultAprendizCubit, DiagnosisResultAprendizState>(
                          builder: (context, state) {
                            final isLoading = state is DiagnosisResultLoading;
                            return SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () => context.read<DiagnosisResultAprendizCubit>().acceptAction(activityId),
                                icon: isLoading
                                    ? const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(
                                          color: AppColors.aSecondary,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined, color: AppColors.aSecondary),
                                label: Text(
                                  isLoading ? 'Procesando...' : 'Guardar en historial',
                                  style: const TextStyle(
                                    color: AppColors.aSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.aSecondary, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
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
            color: AppColors.aSurfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.aOutlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.aSecondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, size: 36, color: AppColors.aSecondary),
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Agenda actualizada!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.aOnSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Se crearon ${activities.length} actividades en tu agenda:',
                style: const TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ...activities.take(3).map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.aOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          a.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.aOnSurface),
                        ),
                      ),
                      Text(
                        '${a.scheduledDate.day}/${a.scheduledDate.month}',
                        style: const TextStyle(fontSize: 12, color: AppColors.aOnSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AprendizMainShell(initialIndex: 3)),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.aOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Ver mi agenda',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 56, color: AppColors.aOnSurfaceVariant),
      ),
    );
  }
}
