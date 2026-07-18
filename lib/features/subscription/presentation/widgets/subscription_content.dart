import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/subscription_entity.dart';
import '../bloc/subscription_bloc.dart';
import '../utils/subscription_plans.dart';
import '../widgets/staggered_reveal.dart';
import 'subscription_active_summary.dart';
import 'subscription_hero_banner.dart';
import 'subscription_plan_card.dart';

/// Contenido principal de [SubscriptionPage] una vez cargado: banner hero,
/// resumen del plan activo (si aplica) y tarjetas de planes.
class SubscriptionContent extends StatelessWidget {
  final SubscriptionState state;
  const SubscriptionContent({super.key, required this.state});

  SubscriptionEntity? get _subscription => switch (state) {
        SubscriptionLoaded(:final subscription) => subscription,
        SubscriptionCancelling(:final subscription) => subscription,
        _ => null,
      };

  bool get _isCancelling => state is SubscriptionCancelling;

  @override
  Widget build(BuildContext context) {
    final subscription = _subscription;
    final isActive = subscription?.isActive ?? false;
    final activePlanId = isActive ? subscription!.planType : 'free';
    final plans = [SubscriptionPlans.free, SubscriptionPlans.monthly, SubscriptionPlans.yearly];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.huge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SubscriptionHeroBanner(),
          const SizedBox(height: AppSpacing.xhuge),
          if (isActive) ...[
            SubscriptionActiveSummary(subscription: subscription!),
            const SizedBox(height: AppSpacing.xxlPlus),
          ],
          for (var i = 0; i < plans.length; i++) ...[
            StaggeredReveal(
              index: i,
              child: SubscriptionPlanCard(plan: plans[i], isActive: activePlanId == plans[i].id),
            ),
            const SizedBox(height: AppSpacing.xxlPlus),
          ],
          const SizedBox(height: AppSpacing.md),
          if (isActive)
            Center(
              child: TextButton.icon(
                onPressed: _isCancelling ? null : () => _confirmCancel(context),
                icon: _isCancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                      )
                    : const Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
                label: Text(
                  _isCancelling ? 'Cancelando...' : 'Cancelar suscripción',
                  style: AppTypography.labelMd.copyWith(color: AppColors.error),
                ),
              ),
            )
          else
            Text(
              'Las suscripciones se renuevan automáticamente. Puedes cancelar en cualquier momento desde esta pantalla.',
              style: AppTypography.etiquetaSm,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: AppSpacing.xhuge),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final bloc = context.read<SubscriptionBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xlPlus)),
        title: const Text('Cancelar suscripción'),
        content: const Text(
          '¿Seguro que deseas cancelar tu suscripción Premium? Perderás el acceso a los beneficios al finalizar el periodo actual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sí, cancelar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(const SubscriptionCancelRequested());
    }
  }
}
