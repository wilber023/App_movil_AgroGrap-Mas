import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/shared_components.dart';
import '../../domain/entities/subscription_entity.dart';
import '../bloc/subscription_bloc.dart';
import '../utils/subscription_plans.dart';
import '../utils/subscription_snackbar.dart';
import '../widgets/staggered_reveal.dart';
import 'checkout_page.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  /// Crea la pantalla con su propio [SubscriptionBloc] (DI propia de la
  /// feature, sin tocar el contenedor global) y dispara la carga inicial.
  static Route<void> route() {
    if (kDebugMode) debugPrint('[SUB-TRACE] 1) SubscriptionPage.route() -- abriendo pantalla');
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => sl<SubscriptionBloc>()..add(const SubscriptionStatusRequested()),
        child: const SubscriptionPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Planes y Suscripciones'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionActionFailure) {
            showSubscriptionSnack(context, state.message);
          }
        },
        builder: (context, state) {
          final child = switch (state) {
            SubscriptionInitial() || SubscriptionLoading() => const _LoadingView(
                key: ValueKey('loading'),
              ),
            SubscriptionLoadFailure(:final message) => _ErrorView(
                key: const ValueKey('error'),
                message: message,
                onRetry: () =>
                    context.read<SubscriptionBloc>().add(const SubscriptionStatusRequested()),
              ),
            _ => RefreshIndicator(
                key: const ValueKey('content'),
                color: AppColors.primary,
                onRefresh: () async {
                  context.read<SubscriptionBloc>().add(const SubscriptionStatusRequested());
                },
                child: _SubscriptionContent(state: state),
              ),
          };
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: child,
          );
        },
      ),
    );
  }
}

// =============================================================================
// Estado de carga
// =============================================================================

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: AppSpacing.xxlPlus),
          Text(
            'Cargando tus planes...',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Estado de error (fallo en la carga inicial -- sin datos previos)
// =============================================================================

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.giant),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 32),
            ),
            const SizedBox(height: AppSpacing.huge),
            Text(
              'No pudimos cargar tus planes',
              style: AppTypography.tituloMd.copyWith(color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xhuge),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xhuge,
                  vertical: AppSpacing.xxl,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Contenido principal
// =============================================================================

class _SubscriptionContent extends StatelessWidget {
  final SubscriptionState state;
  const _SubscriptionContent({required this.state});

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
          _buildHeroBanner(),
          const SizedBox(height: AppSpacing.xhuge),
          if (isActive) ...[
            _buildActiveSummary(context, subscription!),
            const SizedBox(height: AppSpacing.xxlPlus),
          ],
          for (var i = 0; i < plans.length; i++) ...[
            StaggeredReveal(
              index: i,
              child: _buildPlanCard(context, plans[i], isActive: activePlanId == plans[i].id),
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

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxhuge,
        horizontal: AppSpacing.huge,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.forestGreen],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxlPlus),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.onPrimary, size: 26),
          ),
          const SizedBox(height: AppSpacing.xxlPlus),
          Text(
            'Potencia tu Cultivo con AgroGraph Premium',
            style: AppTypography.tituloLg.copyWith(color: AppColors.onPrimary, fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Desbloquea diagnósticos ilimitados, predicciones climáticas avanzadas y gestión de hasta 50 parcelas simultáneas.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.9)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSummary(BuildContext context, SubscriptionEntity subscription) {
    final nextBilling = subscription.nextBillingTime;
    final nextBillingLabel = nextBilling != null
        ? '${nextBilling.day.toString().padLeft(2, '0')}/${nextBilling.month.toString().padLeft(2, '0')}/${nextBilling.year}'
        : '—';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxlPlus),
      decoration: BoxDecoration(
        color: AppColors.statusHealthyBg,
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        border: Border.all(color: AppColors.statusHealthyText.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: AppColors.statusHealthyText),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan ${SubscriptionPlans.byId(subscription.planType).title} activo',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.statusHealthyText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Próximo cobro: $nextBillingLabel',
                  style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    SubscriptionPlanInfo plan, {
    required bool isActive,
  }) {
    final isPremium = plan.id != 'free';
    final highlight = plan.recommended && !isActive;
    final borderColor = highlight
        ? AppColors.warmAmber
        : (isPremium ? AppColors.primary : AppColors.cardBorder);
    final bgColor = isPremium
        ? AppColors.primaryContainer.withValues(alpha: 0.1)
        : AppColors.cardSurface;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: borderColor, width: highlight ? 2.5 : (isPremium ? 2 : 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: isPremium ? 0.08 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (highlight)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.warmAmber,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.xlPlus),
                  topRight: Radius.circular(AppRadius.xlPlus),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: AppColors.onPrimary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'MÁS POPULAR',
                    style: AppTypography.statusPill.copyWith(color: AppColors.onPrimary),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xhuge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: (isPremium ? AppColors.primary : AppColors.forestGreen)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.mdLg),
                      ),
                      child: Icon(
                        plan.icon,
                        size: 18,
                        color: isPremium ? AppColors.primary : AppColors.forestGreen,
                      ),
                    ),
                    Text(
                      plan.title,
                      style: AppTypography.tituloMd.copyWith(
                        color: isPremium ? AppColors.primary : AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (plan.badge != null)
                      StatusPill(
                        label: plan.badge!,
                        background: AppColors.warmAmber.withValues(alpha: 0.18),
                        textColor: AppColors.tertiary,
                      ),
                    if (isActive)
                      StatusPill(
                        label: 'Plan Actual',
                        background: AppColors.statusHealthyBg,
                        textColor: AppColors.statusHealthyText,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  plan.priceLabel,
                  style: AppTypography.tituloLg.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: AppSpacing.xhuge),
                ...plan.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: isPremium ? AppColors.primary : AppColors.forestGreen,
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          child: Text(
                            feature,
                            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (!isActive && isPremium)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => CheckoutPage.push(context, plan: plan.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: highlight ? AppColors.warmAmber : AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
                      ),
                      child: Text(
                        highlight ? 'Elegir el más popular' : 'Mejorar ahora',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
