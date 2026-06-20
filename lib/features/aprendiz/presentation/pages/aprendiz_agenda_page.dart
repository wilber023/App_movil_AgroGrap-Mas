import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../domain/entities/crop_activity_entity.dart';
import '../bloc/aprendiz_my_crop_cubit.dart';
import 'diagnosis_camera_aprendiz_page.dart';

class AprendizAgendaPage extends StatelessWidget {
  const AprendizAgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AprendizMyCropCubit>()..loadPlan(),
      child: const _AprendizAgendaView(),
    );
  }
}

class _AprendizAgendaView extends StatelessWidget {
  const _AprendizAgendaView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        elevation: 0,
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
            final activities = List<CropActivityEntity>.from(state.plan.activities);
            // Ordenar por fecha (más cercanas primero)
            activities.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

            if (activities.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy_rounded, size: 64, color: AppColors.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        'No hay actividades en tu agenda',
                        style: AppTypography.tituloMd.copyWith(color: AppColors.onSurface),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.forestGreen,
              onRefresh: () => context.read<AprendizMyCropCubit>().loadPlan(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return _buildAgendaItem(context, activity);
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAgendaItem(BuildContext context, CropActivityEntity activity) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDate = DateTime(activity.scheduledDate.year, activity.scheduledDate.month, activity.scheduledDate.day);
    
    final isToday = activityDate.isAtSameMomentAs(today);
    final isPast = activityDate.isBefore(today);

    Color statusColor;
    String statusText;

    switch (activity.status) {
      case ActivityStatus.completed:
        statusColor = AppColors.forestGreen;
        statusText = 'Completada';
        break;
      case ActivityStatus.pending:
        if (isPast) {
          statusColor = AppColors.error;
          statusText = 'Atrasada';
        } else if (isToday) {
          statusColor = AppColors.warmAmber;
          statusText = 'Para hoy';
        } else {
          statusColor = AppColors.onSurfaceVariant;
          statusText = 'Pendiente';
        }
        break;
      case ActivityStatus.postponed:
        statusColor = AppColors.warmAmber;
        statusText = 'Pospuesta';
        break;
    }

    final isInspection = activity.title.toLowerCase().contains('inspección') || 
                         activity.title.toLowerCase().contains('inspeccion') ||
                         activity.title.toLowerCase().contains('diagnóstico');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isToday && activity.status == ActivityStatus.pending ? AppColors.warmAmber : AppColors.surfaceVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(activity.scheduledDate),
                  style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: AppTypography.etiquetaSm.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(activity.title, style: AppTypography.etiquetaBold.copyWith(color: AppColors.onSurface)),
            if (activity.description != null && activity.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                activity.description!,
                style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            if (isToday && activity.status == ActivityStatus.pending && isInspection) ...[
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
                  icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                  label: Text('Ir a inspección →', style: AppTypography.labelMd.copyWith(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryDs2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
