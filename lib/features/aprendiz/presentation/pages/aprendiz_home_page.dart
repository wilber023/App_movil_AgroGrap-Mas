import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/crop_activity_entity.dart';
import '../../domain/entities/crop_plan_entity.dart';
import '../bloc/aprendiz_home_cubit.dart';
import 'aprendiz_agenda_page.dart';
import 'crop_history_page.dart';
import 'diagnosis_camera_aprendiz_page.dart';

final _mockPlan = CropPlanEntity(
  id: 'mock',
  userId: 'mock',
  cropName: 'Maíz',
  currentStage: 'Desarrollo Vegetativo',
  startDate: DateTime(2026, 1, 3),
  currentWeek: 6,
  progressPercentage: 56,
  activities: [
    CropActivityEntity(
      id: 'mock-1',
      title: 'Inspección semanal del cultivo',
      description: 'Revisa el sector noroeste por posible estrés hídrico basado en datos satelitales.',
      weekNumber: 6,
      status: ActivityStatus.pending,
      scheduledDate: DateTime.now(),
    ),
  ],
);

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

class _AprendizHomeView extends StatelessWidget {
  const _AprendizHomeView();

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
        backgroundColor: AppColors.aMint,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _TopBar(),
              Expanded(
                child: BlocBuilder<AprendizHomeCubit, AprendizHomeState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.aSecondary),
                      );
                    }
                    final plan = state.cropPlan ?? _mockPlan;
                    return RefreshIndicator(
                      color: AppColors.aSecondary,
                      onRefresh: () => context.read<AprendizHomeCubit>().loadHomeData(),
                      child: _HomeContent(plan: plan),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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
      builder: (_) => _InspectionBottomSheet(activity: activity, cubit: cubit),
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
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
              Positioned(
                top: 10, right: 10,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.aOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final CropPlanEntity plan;
  const _HomeContent({required this.plan});

  @override
  Widget build(BuildContext context) {
    final nextActivity = plan.activities
        .where((a) => a.status == ActivityStatus.pending && a.weekNumber == plan.currentWeek)
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
      children: [
        // Greeting
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Buenos días, Wil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.aPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hoy es un buen día para el campo.',
                    style: TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.aSecondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Plan Free',
                style: TextStyle(fontSize: 11, color: AppColors.aOnSecondaryContainer, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Cultivo card
        _CultivoCard(plan: plan),
        const SizedBox(height: 16),

        // Next activity card
        if (nextActivity != null) _NextActivityCard(activity: nextActivity),
        const SizedBox(height: 16),

        // Quick access
        _QuickAccessRow(),
        const SizedBox(height: 24),

        // Recent events
        _RecentEvents(),
      ],
    );
  }
}

class _CultivoCard extends StatelessWidget {
  final CropPlanEntity plan;
  const _CultivoCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final progress = plan.progressPercentage / 100;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.aSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.eco, color: AppColors.aOnPrimaryFixedVariant, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'MI CULTIVO · ${plan.cropName.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.aOnPrimaryFixedVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.05,
                  ),
                ),
              ),
              const Icon(Icons.more_vert, color: AppColors.aOutline, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Milpa Norte',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.aPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.landscape_outlined, size: 16, color: AppColors.aOnSurfaceVariant),
                        SizedBox(width: 4),
                        Text('2.5 ha', style: TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      backgroundColor: AppColors.aSurfaceVariant,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.aOnPrimaryFixedVariant),
                    ),
                    Text(
                      '${plan.progressPercentage.toInt()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.aPrimary,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso',
                style: TextStyle(fontSize: 11, color: AppColors.aOnSurfaceVariant),
              ),
              Text(
                'Semana ${plan.currentWeek} de 18',
                style: const TextStyle(fontSize: 11, color: AppColors.aOnSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.aSurfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.aOnPrimaryFixedVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextActivityCard extends StatelessWidget {
  final CropActivityEntity activity;
  const _NextActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.aLightGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.aSecondaryContainer),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
      ),
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
                    color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 0.05,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'PRÓXIMA ACTIVIDAD',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.aOnPrimaryFixedVariant,
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
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.aPrimary,
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
            height: 48,
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
              icon: const Icon(Icons.search, color: Colors.white, size: 20),
              label: const Text(
                'Ir a inspección',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.aOrange,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.location_on_outlined, 'Mi ruta', () {}),
      (Icons.assignment_outlined, 'Historial', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropHistoryPage()))),
      (Icons.calendar_month_outlined, 'Agenda', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AprendizAgendaPage()))),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final (icon, label, onTap) = items[i];
          return GestureDetector(
            onTap: onTap,
            child: Container(
              width: 96,
              decoration: BoxDecoration(
                color: AppColors.aSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.aOnPrimaryFixedVariant),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 28, color: AppColors.aOnPrimaryFixedVariant),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: AppColors.aOnPrimaryFixedVariant, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecentEvents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final events = [
      (AppColors.aOnPrimaryFixedVariant, 'Hace 2 días', 'Inspección realizada · sin patología', 'Sector Centro-Sur revisado manualmente.'),
      (AppColors.aOrange, 'Ayer', 'Fertilización pendiente', 'Aplicación de nitrógeno recomendada (Etapa V6).'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Eventos Recientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.aPrimary),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropHistoryPage())),
              child: const Text(
                'VER TODOS',
                style: TextStyle(fontSize: 11, color: AppColors.aOnPrimaryFixedVariant, fontWeight: FontWeight.w600, letterSpacing: 0.05),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...events.asMap().entries.map((entry) {
          final i = entry.key;
          final color = entry.value.$1;
          final timeLabel = entry.value.$2;
          final title = entry.value.$3;
          final subtitle = entry.value.$4;
          final isLast = i == events.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.aMint, width: 2),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppColors.aSurfaceVariant,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(timeLabel, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600, letterSpacing: 0.05)),
                        const SizedBox(height: 4),
                        Text(title, style: const TextStyle(fontSize: 15, color: AppColors.aPrimary, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// Bottom sheet de inspección (Stitch design)
class _InspectionBottomSheet extends StatelessWidget {
  final CropActivityEntity activity;
  final AprendizHomeCubit cubit;
  const _InspectionBottomSheet({required this.activity, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.aOutlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              children: [
                // Eco icon with glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.aPrimaryFixed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.aSurfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.aPrimaryFixed),
                        boxShadow: [BoxShadow(color: AppColors.aPrimaryFixed.withValues(alpha: 0.6), blurRadius: 16, spreadRadius: 4)],
                      ),
                      child: const Icon(Icons.eco, color: AppColors.aPrimaryContainer, size: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.aSecondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.aOnSecondaryContainer),
                      const SizedBox(width: 6),
                      Text(
                        'Semana ${activity.weekNumber} · Inspección programada',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.aOnSecondaryContainer,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.05,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Es momento de inspeccionar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.aOnSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Toma una foto de tus plantas para que el modelo de IA analice su estado actual.',
                  style: TextStyle(fontSize: 15, color: AppColors.aOnSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DiagnosisCameraAprendizPage(
                            weekNumber: activity.weekNumber,
                            activityId: activity.id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    label: const Text(
                      'IR A DIAGNÓSTICO',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.05),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.aOrangeAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      cubit.postponeInspection(activity.id);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.aSecondary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'POSPONER PARA MAÑANA',
                      style: TextStyle(fontSize: 12, color: AppColors.aSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.05),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
