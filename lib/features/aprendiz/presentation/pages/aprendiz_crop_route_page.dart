import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/crop_activity_entity.dart';
import '../../domain/entities/crop_plan_entity.dart';
import '../bloc/aprendiz_my_crop_cubit.dart';
import 'aprendiz_crop_register_page.dart';
import 'aprendiz_my_crop_page.dart';
import 'diagnosis_camera_aprendiz_page.dart';

final _mockRoutePlan = CropPlanEntity(
  id: 'mock',
  userId: 'mock',
  cropName: 'Maíz',
  currentStage: 'Desarrollo Vegetativo',
  startDate: DateTime(2026, 1, 3),
  currentWeek: 6,
  progressPercentage: 67,
  activities: [
    CropActivityEntity(id: 'm1', title: 'Inspección semana 1', description: 'Inspección inicial.', weekNumber: 1, status: ActivityStatus.completed, scheduledDate: DateTime(2026, 1, 10)),
    CropActivityEntity(id: 'm2', title: 'Inspección semana 2', description: 'Control de plagas.', weekNumber: 2, status: ActivityStatus.completed, scheduledDate: DateTime(2026, 1, 17)),
    CropActivityEntity(id: 'm3', title: 'Fertilización semana 3', description: 'Nitrógeno aplicado.', weekNumber: 3, status: ActivityStatus.completed, scheduledDate: DateTime(2026, 1, 24)),
    CropActivityEntity(id: 'm4', title: 'Inspección semana 4', description: 'Revisión visual.', weekNumber: 4, status: ActivityStatus.completed, scheduledDate: DateTime(2026, 1, 31)),
    CropActivityEntity(id: 'm5', title: 'Seguimiento semana 5', description: 'Seguimiento preventivo.', weekNumber: 5, status: ActivityStatus.postponed, scheduledDate: DateTime(2026, 2, 7)),
    CropActivityEntity(id: 'm6', title: 'Desarrollo Vegetativo', description: 'Monitorear aparición de hojas nuevas, control de maleza y humedad del suelo. Atención especial a posibles signos de plagas tempranas en el envés de la hoja.', weekNumber: 6, status: ActivityStatus.pending, scheduledDate: DateTime.now()),
    CropActivityEntity(id: 'm7', title: 'Inspección semana 7', description: 'Control preventivo.', weekNumber: 7, status: ActivityStatus.pending, scheduledDate: DateTime.now().add(const Duration(days: 7))),
  ],
);

class AprendizCropRoutePage extends StatelessWidget {
  const AprendizCropRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AprendizMyCropCubit>()..loadPlan(),
      child: const _AprendizCropRouteView(),
    );
  }
}

class _AprendizCropRouteView extends StatefulWidget {
  const _AprendizCropRouteView();

  @override
  State<_AprendizCropRouteView> createState() => _AprendizCropRouteViewState();
}

class _AprendizCropRouteViewState extends State<_AprendizCropRouteView> {
  bool _showOfflineBanner = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aMint,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(),
            BlocBuilder<AprendizMyCropCubit, AprendizMyCropState>(
              builder: (context, state) {
                if (state is AprendizMyCropLoaded && state.isOffline && _showOfflineBanner) {
                  return _OfflineBanner(onClose: () => setState(() => _showOfflineBanner = false));
                }
                return const SizedBox.shrink();
              },
            ),
            Expanded(
              child: BlocBuilder<AprendizMyCropCubit, AprendizMyCropState>(
                builder: (context, state) {
                  if (state is AprendizMyCropLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.aSecondary),
                    );
                  }
                  final plan = state is AprendizMyCropLoaded ? state.plan : _mockRoutePlan;
                  return _RouteContent(plan: plan);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.aPrimaryContainer,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {},
          ),
          const Expanded(
            child: Text(
              'AgroGraph IA',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final VoidCallback onClose;
  const _OfflineBanner({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.aTertiaryFixed,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 16, color: AppColors.aOnTertiaryFixedVariant),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Modo fuera de línea · Cambios se sinc. pronto',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.aOnTertiaryFixedVariant,
                letterSpacing: 0.05,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, size: 16, color: AppColors.aOnTertiaryFixedVariant),
          ),
        ],
      ),
    );
  }
}

class _RouteContent extends StatelessWidget {
  final CropPlanEntity plan;
  const _RouteContent({required this.plan});

  @override
  Widget build(BuildContext context) {
    final totalWeeks = 18;
    final harvestDate = plan.startDate.add(const Duration(days: 18 * 7));
    final progress = plan.progressPercentage / 100;

    final completed = plan.activities.where((a) => a.status == ActivityStatus.completed).length;
    final pending = plan.activities.where((a) => a.status == ActivityStatus.pending).length;
    final postponed = plan.activities.where((a) => a.status == ActivityStatus.postponed).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cultivo Header Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.aPrimaryFixed,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mi Cultivo · ${plan.cropName}',
                            style: const TextStyle(fontSize: 14, color: AppColors.aOnPrimaryFixedVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Milpa Norte',
                            style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700,
                              color: AppColors.aOnPrimaryFixed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SmallProgressRing(progress: progress, label: '${plan.progressPercentage.toInt()}%'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: AppColors.aOnPrimaryFixedVariant),
                          const SizedBox(width: 8),
                          Text(
                            'Semana ${plan.currentWeek} de $totalWeeks  |  Cosecha: ${_formatDate(harvestDate)}',
                            style: const TextStyle(fontSize: 14, color: AppColors.aOnPrimaryFixedVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatusChip(label: '$completed Completadas', color: AppColors.aSecondary, bg: AppColors.aSecondaryContainer),
                          const SizedBox(width: 8),
                          _StatusChip(label: '$pending Pendientes', color: AppColors.aOnSurfaceVariant, bg: AppColors.aSurfaceContainer),
                          if (postponed > 0) ...[
                            const SizedBox(width: 8),
                            _StatusChip(label: '$postponed Pospuestas', color: AppColors.error, bg: AppColors.errorContainer),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Ver estado button
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AprendizMyCropPage())),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.aSurfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.aOutlineVariant),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.monitor_heart_outlined, color: AppColors.aSecondary, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ver estado de mi cultivo',
                      style: TextStyle(fontSize: 14, color: AppColors.aOnSurface, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.aOnSurfaceVariant),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Container(
                width: 2, height: 16,
                color: AppColors.aSecondary,
                margin: const EdgeInsets.only(right: 8),
              ),
              const Text(
                'RUTA DE INSPECCIÓN',
                style: TextStyle(
                  fontSize: 11, letterSpacing: 0.05,
                  fontWeight: FontWeight.w600,
                  color: AppColors.aOnSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Activities list
          _ActivitiesSection(plan: plan),

          const SizedBox(height: 24),

          // Register new crop
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AprendizCropRegisterPage())),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.aSurfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.aOutlineVariant, style: BorderStyle.solid),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline, color: AppColors.aSecondary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Registrar otro cultivo',
                    style: TextStyle(fontSize: 14, color: AppColors.aSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ActivitiesSection extends StatefulWidget {
  final CropPlanEntity plan;
  const _ActivitiesSection({required this.plan});

  @override
  State<_ActivitiesSection> createState() => _ActivitiesSectionState();
}

class _ActivitiesSectionState extends State<_ActivitiesSection> {
  bool _pastExpanded = false;

  @override
  Widget build(BuildContext context) {
    final past = widget.plan.activities.where((a) => a.weekNumber < widget.plan.currentWeek).toList();
    final active = widget.plan.activities.where((a) => a.weekNumber == widget.plan.currentWeek && a.status == ActivityStatus.pending).toList();
    final future = widget.plan.activities.where((a) => a.weekNumber > widget.plan.currentWeek && a.status == ActivityStatus.pending).toList();

    return Column(
      children: [
        if (past.isNotEmpty) ...[
          GestureDetector(
            onTap: () => setState(() => _pastExpanded = !_pastExpanded),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.aSurfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.aOutlineVariant),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Semanas anteriores (1 – ${widget.plan.currentWeek - 1})',
                      style: const TextStyle(fontSize: 14, color: AppColors.aOnSurface),
                    ),
                  ),
                  Icon(
                    _pastExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.aOnSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_pastExpanded)
            ...past.map((a) => _CompactActivityItem(activity: a)),
          const SizedBox(height: 12),
        ],

        // Active week card
        ...active.map((a) => _ActiveWeekCard(activity: a)),

        if (future.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.aSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.aOutlineVariant),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${future.length} actividades · semanas ${widget.plan.currentWeek + 1} a 18',
                    style: const TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: AppColors.aOnSurfaceVariant),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ActiveWeekCard extends StatelessWidget {
  final CropActivityEntity activity;
  const _ActiveWeekCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.aOutlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            decoration: const BoxDecoration(
              color: AppColors.aOrange,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.aOrange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HOY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.05,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SEMANA ${activity.weekNumber}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.aOnSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.05,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.aOnSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style: const TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DiagnosisCameraAprendizPage(
                            weekNumber: activity.weekNumber,
                            activityId: activity.id,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                      label: const Text(
                        'Realizar inspección',
                        style: TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 0.05),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.aOrange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
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
}

class _CompactActivityItem extends StatelessWidget {
  final CropActivityEntity activity;
  const _CompactActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (activity.status) {
      ActivityStatus.completed => (Icons.check_circle, AppColors.aSecondary),
      ActivityStatus.postponed => (Icons.watch_later, AppColors.error),
      _ => (Icons.radio_button_unchecked, AppColors.aOutline),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(activity.title, style: const TextStyle(fontSize: 14, color: AppColors.aOnSurface))),
          Text('Sem ${activity.weekNumber}', style: const TextStyle(fontSize: 11, color: AppColors.aOnSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SmallProgressRing extends StatelessWidget {
  final double progress;
  final String label;
  const _SmallProgressRing({required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: AppColors.aSurfaceVariant.withValues(alpha: 0.4),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.aPrimary),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.aPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _StatusChip({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
