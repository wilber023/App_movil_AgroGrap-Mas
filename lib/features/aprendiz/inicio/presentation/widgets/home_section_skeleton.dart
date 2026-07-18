import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';

/// Skeleton de carga reutilizado por todas las tarjetas de Inicio mientras
/// `AprendizHomeBloc` resuelve el resumen del dashboard.
class HomeSectionSkeleton extends StatefulWidget {
  final double height;

  const HomeSectionSkeleton({super.key, this.height = 96});

  @override
  State<HomeSectionSkeleton> createState() => _HomeSectionSkeletonState();
}

class _HomeSectionSkeletonState extends State<HomeSectionSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(AppColors.aSurfaceVariant, AppColors.aSurfaceContainerLow, _controller.value),
            borderRadius: BorderRadius.circular(AppRadius.xlPlus),
          ),
        );
      },
    );
  }
}
