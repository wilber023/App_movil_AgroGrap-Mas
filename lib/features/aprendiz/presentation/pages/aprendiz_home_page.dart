import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../domain/entities/crop_activity_entity.dart';
import '../../domain/entities/crop_health_entity.dart';
import '../../domain/entities/crop_plan_entity.dart';
import '../bloc/aprendiz_home_cubit.dart';
import 'diagnosis_camera_aprendiz_page.dart';

class AprendizHomePage extends StatelessWidget {
  const AprendizHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AprendizHomeCubit>()..loadHomeData(),
      child: const _AprendizHomeView(),
    );
  }
}

class _AprendizHomeView extends StatefulWidget {
  const _AprendizHomeView();

  @override
  State<_AprendizHomeView> createState() => _AprendizHomeViewState();
}

class _AprendizHomeViewState extends State<_AprendizHomeView> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AprendizHomeCubit, AprendizHomeState>(
      listenWhen: (previous, current) =>
          current.dueInspection != null && !current.modalAlreadyShown && !current.isLoading,
      listener: (context, state) {
        if (state.dueInspection != null && !state.modalAlreadyShown) {
          context.read<AprendizHomeCubit>().markModalAsShown();
          _showInspectionModal(context, state.dueInspection!);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inicio - Productor Guiado'),
          elevation: 0,
        ),
        body: BlocBuilder<AprendizHomeCubit, AprendizHomeState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.forestGreen));
            }
            if (state.errorMessage != null) {
              return ErrorStateWidget(
                message: state.errorMessage!,
                onRetry: () => context.read<AprendizHomeCubit>().loadHomeData(),
              );
            }
            if (state.cropPlan != null) {
              return RefreshIndicator(
                color: AppColors.forestGreen,
                onRefresh: () => context.read<AprendizHomeCubit>().loadHomeData(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (state.isOffline)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_off_rounded, size: 16, color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Modo fuera de línea - Mostrando datos locales',
                                style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                    // Welcome
                    Text('Buenos días', style: AppTypography.tituloMd.copyWith(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 16),
                    
                    // Crop Summary Card
                    _buildCropSummary(state.cropPlan!),
                    const SizedBox(height: 24),
                    
                    // Health Indicator
                    if (state.cropHealth != null)
                      _buildCropHealth(state.cropHealth!),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }
            return const Center(child: Text('No hay datos disponibles.'));
          },
        ),
      ),
    );
  }

  Widget _buildCropSummary(CropPlanEntity plan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.forestGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cultivo Actual', style: AppTypography.etiquetaBold.copyWith(color: AppColors.forestGreen)),
              Text('Semana ${plan.currentWeek}', style: AppTypography.labelMd),
            ],
          ),
          const SizedBox(height: 8),
          Text(plan.cropName, style: AppTypography.tituloLg),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.grass_rounded, size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(plan.currentStage, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: plan.progressPercentage / 100,
              backgroundColor: AppColors.surfaceVariant,
              color: AppColors.forestGreen,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text('${plan.progressPercentage.toInt()}% completado', style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildCropHealth(CropHealthEntity health) {
    Color statusColor;
    IconData statusIcon;
    
    switch (health.status.toLowerCase()) {
      case 'saludable':
        statusColor = AppColors.forestGreen;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'en riesgo':
        statusColor = AppColors.warmAmber;
        statusIcon = Icons.warning_rounded;
        break;
      case 'crítico':
      case 'critico':
        statusColor = AppColors.error;
        statusIcon = Icons.error_rounded;
        break;
      default:
        statusColor = AppColors.onSurfaceVariant;
        statusIcon = Icons.help_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Estado de Salud del Cultivo', style: AppTypography.tituloMd),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estado General', style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant)),
                        Text(health.status, style: AppTypography.tituloMd.copyWith(color: statusColor)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHealthStat('${health.healthyPlantsPercentage}%', 'Plantas\nSanas', AppColors.forestGreen),
                  Container(width: 1, height: 40, color: AppColors.surfaceVariant),
                  _buildHealthStat('${health.affectedPlantsPercentage}%', 'Plantas\nAfectadas', AppColors.error),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.history_rounded, size: 16, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Última inspección: ${_formatDate(health.lastInspectionDate)}',
                    style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: AppTypography.tituloLg.copyWith(color: color)),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
      ],
    );
  }

  void _showInspectionModal(BuildContext context, CropActivityEntity activity) {
    final cubit = context.read<AprendizHomeCubit>();

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
                child: const Icon(Icons.eco_rounded, size: 32, color: AppColors.forestGreen),
              ),
              const SizedBox(height: 16),
              Text(
                'Es momento de inspeccionar',
                style: AppTypography.tituloLg.copyWith(color: AppColors.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Semana ${activity.weekNumber} · Inspección programada',
                  style: AppTypography.labelMd.copyWith(color: AppColors.forestGreen),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Toma una foto de tus plantas para que el modelo de IA analice su estado actual y actualice tu ruta de cultivo.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                     'Programada para: ${_formatDate(activity.scheduledDate)}',
                    style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Cierra el modal
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DiagnosisCameraAprendizPage(
                          weekNumber: activity.weekNumber,
                          activityId: activity.id,
                        ),
                      ),
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
                  child: const Text('Ir a diagnóstico →'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Cierra el modal
                    cubit.postponeInspection(activity.id);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.forestGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Posponer para mañana'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
