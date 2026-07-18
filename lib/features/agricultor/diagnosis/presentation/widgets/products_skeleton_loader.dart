import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Skeleton animado mostrado mientras se cargan las recomendaciones de
/// productos en [DiagnosisResultPage].
class ProductsSkeletonLoader extends StatefulWidget {
  const ProductsSkeletonLoader({super.key});

  @override
  State<ProductsSkeletonLoader> createState() =>
      _ProductsSkeletonLoaderState();
}

class _ProductsSkeletonLoaderState extends State<ProductsSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        final grad = LinearGradient(
          colors: const [
            AppColors.diagnosisSkeletonLight,
            AppColors.diagnosisSkeletonDark,
            AppColors.diagnosisSkeletonLight,
          ],
          stops: [
            (t - 0.3).clamp(0.0, 1.0),
            t.clamp(0.0, 1.0),
            (t + 0.3).clamp(0.0, 1.0),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.none, AppSpacing.xxl, AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sBox(160, 15, grad),
                  const SizedBox(height: AppSpacing.xsPlus),
                  _sBox(120, 10, grad),
                ],
              ),
            ),
            _skeletonCard(grad),
            const SizedBox(height: AppSpacing.lg),
            _skeletonCard(grad),
          ],
        );
      },
    );
  }

  Widget _skeletonCard(LinearGradient grad) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.parcelsTrackGrey, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sBox(64, 64, grad, radius: 10),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _sBox(null, 13, grad)),
                    const SizedBox(width: AppSpacing.md),
                    _sBox(70, 13, grad),
                  ],
                ),
                const SizedBox(height: AppSpacing.xsPlus),
                _sBox(90, 10, grad),
                const SizedBox(height: AppSpacing.lg),
                _sBox(null, 6, grad, radius: 3),
                const SizedBox(height: AppSpacing.md),
                _sBox(100, 20, grad, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sBox(double? w, double h, LinearGradient grad, {double radius = 4}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: grad,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
