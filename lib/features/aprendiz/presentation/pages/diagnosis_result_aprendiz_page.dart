import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../diagnosis/domain/entities/diagnosis_entity.dart';
import '../../../diagnosis/presentation/bloc/llm_diagnosis_cubit.dart';
import '../../domain/entities/crop_activity_entity.dart';
import '../bloc/diagnosis_result_aprendiz_cubit.dart';
import 'aprendiz_main_shell.dart';
import 'aprendiz_recommended_action_page.dart';

// Tipografía Inter consistente con el resto de la app (ver AppTypography).
const String _kFont = 'Inter';

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
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<DiagnosisResultAprendizCubit>()),
        BlocProvider(
          create: (_) {
            final cubit = sl<LlmDiagnosisCubit>();
            if (diagnosis.llmResponse != null) {
              cubit.loadCached(diagnosis.llmResponse!);
            }
            return cubit;
          },
        ),
      ],
      child: _DiagnosisResultAprendizView(diagnosis: diagnosis, activityId: activityId),
    );
  }
}

class _DiagnosisResultAprendizView extends StatefulWidget {
  final DiagnosisEntity diagnosis;
  final String activityId;

  const _DiagnosisResultAprendizView({
    required this.diagnosis,
    required this.activityId,
  });

  @override
  State<_DiagnosisResultAprendizView> createState() => _DiagnosisResultAprendizViewState();
}

class _DiagnosisResultAprendizViewState extends State<_DiagnosisResultAprendizView> {
  DiagnosisEntity get diagnosis => widget.diagnosis;
  String get activityId => widget.activityId;

  @override
  void initState() {
    super.initState();
    if (diagnosis.llmResponse == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<LlmDiagnosisCubit>().consultar(diagnosis: diagnosis);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHealthy = diagnosis.statusLabel == 'Saludable';

    return MultiBlocListener(
      listeners: [
        BlocListener<DiagnosisResultAprendizCubit, DiagnosisResultAprendizState>(
          listener: (context, state) {
            if (state is AgendaUpdated) {
              _showAgendaUpdatedModal(context, state.newActivities);
            } else if (state is DiagnosisResultError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message, style: const TextStyle(fontFamily: _kFont, color: Colors.white)),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
        BlocListener<LlmDiagnosisCubit, LlmDiagnosisState>(
          listener: (context, state) {
            if (state is LlmDiagnosisLoaded && diagnosis.llmResponse == null) {
              context.read<DiagnosisResultAprendizCubit>().saveLlmResponse(
                    diagnosisId: diagnosis.id,
                    llmResponse: state.response,
                  );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.aMint,
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
                        'Resultado de tu análisis',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: _kFont,
                          color: Colors.white,
                          fontSize: 17,
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
                      // Foto analizada
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: diagnosis.imagePath != null &&
                                File(diagnosis.imagePath!).existsSync()
                            ? Image.file(
                                File(diagnosis.imagePath!),
                                height: 210,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : _ImagePlaceholder(),
                      ),

                      const SizedBox(height: 16),

                      // Identificación de la planta
                      _Card(
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: const BoxDecoration(
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
                                    'PLANTA IDENTIFICADA',
                                    style: TextStyle(
                                      fontFamily: _kFont,
                                      fontSize: 11,
                                      color: AppColors.aOnSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    diagnosis.cropName,
                                    style: const TextStyle(
                                      fontFamily: _kFont,
                                      fontSize: 17,
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
                                '${(diagnosis.confidence * 100).toStringAsFixed(0)}% seguro',
                                style: const TextStyle(
                                  fontFamily: _kFont,
                                  fontSize: 11,
                                  color: AppColors.aOnSecondaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (isHealthy) ...[
                        // Variante: cultivo sano
                        _Card(
                          color: AppColors.aMint,
                          borderColor: AppColors.aSecondaryContainer,
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                          child: Column(
                            children: [
                              Container(
                                width: 64, height: 64,
                                decoration: const BoxDecoration(
                                  color: AppColors.aSecondaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle_outline, color: AppColors.aSecondary, size: 34),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                '¡Tu cultivo está sano!',
                                style: TextStyle(
                                  fontFamily: _kFont,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.aSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'No encontramos señales de enfermedad. Sigue cuidando tu cultivo como hasta ahora.',
                                style: TextStyle(fontFamily: _kFont, fontSize: 14, color: AppColors.aOnSurfaceVariant, height: 1.5),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        _buildLlmSection(context),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.aOrange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Continuar',
                              style: TextStyle(fontFamily: _kFont, color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Variante: se encontró algo que revisar
                        _Card(
                          color: AppColors.aDiseaseCardBg,
                          borderColor: AppColors.aDiseaseCardBorder,
                          padding: EdgeInsets.zero,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0, top: 0, bottom: 0,
                                child: Container(
                                  width: 4,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.search_rounded, color: AppColors.error, size: 16),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'ENCONTRAMOS ALGO QUE REVISAR',
                                          style: TextStyle(
                                            fontFamily: _kFont,
                                            fontSize: 11,
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      diagnosis.diseaseName,
                                      style: const TextStyle(
                                        fontFamily: _kFont,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.aDiseaseCardText,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'En tu cultivo de ${diagnosis.cropName}',
                                      style: const TextStyle(
                                        fontFamily: _kFont,
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
                        _buildLlmSection(context),
                        const SizedBox(height: 16),

                        // Aviso práctico: qué pasa si no se atiende a tiempo
                        _Card(
                          color: AppColors.aWarningBg,
                          borderColor: AppColors.aWarningBorder,
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_outline, color: AppColors.aOrange, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Si no se atiende pronto, puede extenderse al resto del cultivo.',
                                  style: TextStyle(fontFamily: _kFont, fontSize: 13, color: AppColors.aWarningText, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // CTA principal: ver acción recomendada
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final llmState = context.read<LlmDiagnosisCubit>().state;
                              final llmResponse = llmState is LlmDiagnosisLoaded ? llmState.response : null;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AprendizRecommendedActionPage(
                                    diseaseName: diagnosis.diseaseName,
                                    cropName: diagnosis.cropName,
                                    llmResponse: llmResponse,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                            label: const Text(
                              'Ver qué hacer ahora',
                              style: TextStyle(fontFamily: _kFont, color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.aOrange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),

                        // El seguimiento en agenda solo aplica a inspecciones guiadas
                        // (ligadas a una actividad real del plan de cultivo).
                        if (activityId.isNotEmpty) ...[
                          const SizedBox(height: 12),
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
                                      : const Icon(Icons.event_available_outlined, color: AppColors.aSecondary),
                                  label: Text(
                                    isLoading ? 'Actualizando tu agenda...' : 'Actualizar mi agenda de seguimiento',
                                    style: const TextStyle(
                                      fontFamily: _kFont,
                                      color: AppColors.aSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.aSecondary, width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
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

  // ---------------------------------------------------------------------------
  // Sección educativa: explicación del asistente IA (LLM), en lenguaje sencillo
  // ---------------------------------------------------------------------------

  Widget _buildLlmSection(BuildContext context) {
    return BlocBuilder<LlmDiagnosisCubit, LlmDiagnosisState>(
      builder: (context, state) {
        if (state is LlmDiagnosisIdle || state is LlmDiagnosisLoading) {
          return _Card(
            child: Row(
              children: [
                const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(color: AppColors.aSecondary, strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Preparando una explicación fácil de entender para ti...',
                    style: TextStyle(fontFamily: _kFont, fontSize: 13, color: AppColors.aOnSurfaceVariant),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is LlmDiagnosisError) {
          return _Card(
            child: Row(
              children: [
                const Icon(Icons.wifi_off_outlined, size: 18, color: AppColors.aOnSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No pudimos preparar la explicación ahora mismo.',
                    style: const TextStyle(fontFamily: _kFont, fontSize: 12, color: AppColors.aOnSurfaceVariant),
                  ),
                ),
                TextButton(
                  onPressed: () => context.read<LlmDiagnosisCubit>().consultar(diagnosis: diagnosis),
                  child: const Text('Reintentar', style: TextStyle(fontFamily: _kFont, color: AppColors.aSecondary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        }

        if (state is LlmDiagnosisLoaded) {
          final r = state.response;
          return _Card(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppColors.aMint, shape: BoxShape.circle),
                        child: const Icon(Icons.auto_awesome, size: 15, color: AppColors.aSecondary),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Te lo explicamos fácil',
                        style: TextStyle(fontFamily: _kFont, fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.aOnSurface),
                      ),
                    ],
                  ),
                ),
                if (r.diagnostico.isNotEmpty) _llmBlock('¿Qué está pasando?', r.diagnostico),
                if (r.tratamiento.isNotEmpty) _llmBlock('¿Qué puedo hacer?', r.tratamiento),
                if (r.prevencion.isNotEmpty) _llmBlock('¿Cómo lo prevengo la próxima vez?', r.prevencion),
                const SizedBox(height: 8),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _llmBlock(String title, String content) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontFamily: _kFont, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.aSecondary),
          ),
          const SizedBox(height: 5),
          Text(
            content,
            style: const TextStyle(fontFamily: _kFont, fontSize: 14, color: AppColors.aOnSurface, height: 1.5),
          ),
        ],
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
                decoration: const BoxDecoration(
                  color: AppColors.aSecondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, size: 36, color: AppColors.aSecondary),
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Agenda actualizada!',
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.aOnSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Se crearon ${activities.length} actividades en tu agenda:',
                style: const TextStyle(fontFamily: _kFont, fontSize: 14, color: AppColors.aOnSurfaceVariant),
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
                          style: const TextStyle(fontFamily: _kFont, fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.aOnSurface),
                        ),
                      ),
                      Text(
                        '${a.scheduledDate.day}/${a.scheduledDate.month}',
                        style: const TextStyle(fontFamily: _kFont, fontSize: 12, color: AppColors.aOnSurfaceVariant),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Ver mi agenda',
                    style: TextStyle(fontFamily: _kFont, color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
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

/// Card base reutilizada por toda la pantalla de resultado: mismo radio,
/// borde y sombra sutil para que todas las secciones se sientan parte de
/// un mismo sistema visual.
class _Card extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  const _Card({
    required this.child,
    this.color = AppColors.aSurfaceContainerLowest,
    this.borderColor = AppColors.aOutlineVariant,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 56, color: AppColors.aOnSurfaceVariant),
      ),
    );
  }
}
