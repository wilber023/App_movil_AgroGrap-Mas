import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../domain/entities/crop_activity_entity.dart';
import '../../domain/entities/crop_plan_entity.dart';
import '../bloc/aprendiz_my_crop_cubit.dart';
import 'aprendiz_crop_register_page.dart';
import 'diagnosis_camera_aprendiz_page.dart';

class AprendizMyCropPage extends StatelessWidget {
  const AprendizMyCropPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AprendizMyCropCubit>()..loadPlan(),
      child: const _AprendizMyCropView(),
    );
  }
}

class _AprendizMyCropView extends StatelessWidget {
  const _AprendizMyCropView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<AprendizMyCropCubit, AprendizMyCropState>(
          builder: (context, state) {
            if (state is AprendizMyCropLoaded) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mi Cultivo · ${state.plan.cropName}', style: AppTypography.tituloMd),
                  Text('Milpa Norte', style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant)), // Hardcodeado parcela
                ],
              );
            }
            return const Text('Mi Cultivo');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Agregar otro cultivo',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AprendizCropRegisterPage()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AprendizMyCropCubit, AprendizMyCropState>(
        builder: (context, state) {
          if (state is AprendizMyCropLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.forestGreen));
          }
          if (state is AprendizMyCropError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<AprendizMyCropCubit>().loadPlan(),
            );
          }
          if (state is AprendizMyCropLoaded) {
            return _buildContent(context, state.plan, state.isOffline);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, CropPlanEntity plan, bool isOffline) {
    final completed = plan.activities.where((a) => a.status == ActivityStatus.completed).length;
    final pending = plan.activities.where((a) => a.status == ActivityStatus.pending).length;
    final postponed = plan.activities.where((a) => a.status == ActivityStatus.postponed).length;

    // Supongamos 18 semanas total como dice el diseño
    final totalWeeks = 18; 
    
    // Obtener la fecha de cosecha (ejemplo agregando 18 semanas a start date)
    final harvestDate = plan.startDate.add(const Duration(days: 18 * 7));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isOffline)
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
                      'Modo fuera de línea - Cambios se sincronizarán pronto',
                      style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          
          // Resumen Circular
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceVariant),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            value: plan.progressPercentage / 100,
                            strokeWidth: 6,
                            backgroundColor: AppColors.surfaceVariant,
                            color: AppColors.forestGreen,
                          ),
                        ),
                        Text(
                          '${plan.progressPercentage.toInt()}%',
                          style: AppTypography.tituloMd.copyWith(color: AppColors.forestGreen),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Semana ${plan.currentWeek} de $totalWeeks', style: AppTypography.tituloMd),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                'Cosecha: ${_formatDate(harvestDate)}',
                                style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPill('$completed COMPLETADAS', AppColors.forestGreen),
                    _buildPill('$pending PENDIENTES', AppColors.onSurfaceVariant),
                    _buildPill('$postponed POSPUESTA(S)', AppColors.error),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'RUTA DE INSPECCIÓN',
            style: AppTypography.etiquetaBold.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          
          // Agrupamos actividades
          _buildActivitiesList(context, plan),
        ],
      ),
    );
  }

  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: AppTypography.etiquetaSm.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActivitiesList(BuildContext context, CropPlanEntity plan) {
    // Simulamos un agrupador por rango de semanas.
    // Para simplificar, mostraremos la actividad activa (si hay) y un grupo colapsado de siguientes.
    
    final activeActivities = plan.activities.where((a) => a.weekNumber == plan.currentWeek && a.status == ActivityStatus.pending).toList();
    final pastActivities = plan.activities.where((a) => a.weekNumber < plan.currentWeek || a.status != ActivityStatus.pending).toList();
    final futureActivities = plan.activities.where((a) => a.weekNumber > plan.currentWeek && a.status == ActivityStatus.pending).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pasadas colapsables
        if (pastActivities.isNotEmpty)
          ExpansionTile(
            title: Text('Semanas anteriores (1-${plan.currentWeek > 1 ? plan.currentWeek - 1 : 1})'),
            children: pastActivities.map((a) => _buildActivityItem(context, a, isActive: false)).toList(),
          ),
        
        // Activas
        if (activeActivities.isNotEmpty)
          ...activeActivities.map((a) => _buildActivityItem(context, a, isActive: true)),

        // Futuras colapsables
        if (futureActivities.isNotEmpty)
          ExpansionTile(
            title: Text('${futureActivities.length} actividades pendientes · semanas ${plan.currentWeek + 1} a 18'),
            children: futureActivities.map((a) => _buildActivityItem(context, a, isActive: false)).toList(),
          ),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, CropActivityEntity activity, {required bool isActive}) {
    IconData icon;
    Color iconColor;
    
    switch (activity.status) {
      case ActivityStatus.completed:
        icon = Icons.check_circle_rounded;
        iconColor = AppColors.forestGreen;
        break;
      case ActivityStatus.pending:
        icon = Icons.radio_button_unchecked_rounded;
        iconColor = AppColors.onSurfaceVariant;
        break;
      case ActivityStatus.postponed:
        icon = Icons.watch_later_rounded;
        iconColor = AppColors.error;
        break;
    }

    if (isActive) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warmAmber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warmAmber),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.radio_button_checked_rounded, color: AppColors.warmAmber),
                const SizedBox(width: 8),
                Text('HOY · SEMANA ${activity.weekNumber}', style: AppTypography.etiquetaBold.copyWith(color: AppColors.warmAmber)),
              ],
            ),
            const SizedBox(height: 8),
            Text(activity.title, style: AppTypography.tituloMd),
            const SizedBox(height: 4),
            Text(
              activity.description ?? 'Monitorear aparición de hojas nuevas, control de maleza.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DiagnosisCameraAprendizPage(
                        weekNumber: activity.weekNumber,
                        activityId: activity.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                label: Text('Realizar inspección ahora →', style: AppTypography.labelMd.copyWith(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryDs2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(activity.title, style: AppTypography.labelMd),
      subtitle: Text('Semana ${activity.weekNumber}'),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
