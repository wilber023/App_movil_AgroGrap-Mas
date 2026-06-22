import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/aprendiz_my_crop_cubit.dart';

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
      backgroundColor: AppColors.aSurface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with back arrow
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
                      'Estado de mi cultivo',
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
              child: BlocBuilder<AprendizMyCropCubit, AprendizMyCropState>(
                builder: (context, state) {
                  if (state is AprendizMyCropLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.aSecondary),
                    );
                  }
                  final week = state is AprendizMyCropLoaded ? state.plan.currentWeek : 6;
                  return _CropStatusContent(currentWeek: week);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropStatusContent extends StatelessWidget {
  final int currentWeek;
  const _CropStatusContent({required this.currentWeek});

  @override
  Widget build(BuildContext context) {
    // TODO: wire to CropHealthEntity from a dedicated health cubit
    const healthPercent = 0.85;
    final factors = [
      (Icons.shield_outlined, 'Enfermedades', 0.90),
      (Icons.check_circle_outline, 'Cumplimiento', 0.80),
      (Icons.visibility_outlined, 'Inspecciones', 0.75),
      (Icons.trending_up, 'Seguimientos', 0.85),
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Health ring
          _HealthRing(percent: healthPercent),
          const SizedBox(height: 16),

          // Crop name + week badge
          const Text(
            'Maíz · Milpa Norte',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.aOnSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.aSurfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.aOutlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month, size: 16, color: AppColors.aOnSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Semana $currentWeek',
                  style: const TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Factors card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.aSurfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.aSurfaceContainerHigh),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: factors.map((f) {
                  final icon = f.$1;
                  final label = f.$2;
                  final value = f.$3;
                  final isLast = f == factors.last;

                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(icon, color: AppColors.aSecondary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.aOnSurface,
                                ),
                              ),
                            ),
                            Text(
                              '${(value * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.aPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 10,
                            backgroundColor: AppColors.aSurfaceVariant,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.aSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.aSurfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(16),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.aSecondary, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Los indicadores se actualizan con base en las últimas sincronizaciones y reportes ingresados por los técnicos de campo.',
                      style: TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant, height: 1.5),
                    ),
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
}

class _HealthRing extends StatelessWidget {
  final double percent;
  const _HealthRing({required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.aSurfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.aSecondary),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(percent * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.aPrimary,
                ),
              ),
              const Text(
                'SALUD',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.aOutline,
                  letterSpacing: 0.08,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
