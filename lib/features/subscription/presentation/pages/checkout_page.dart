import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/security/screen_security.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/subscription_bloc.dart';
import '../utils/subscription_plans.dart';
import '../utils/subscription_snackbar.dart';
import '../widgets/card_number_field.dart';

class CheckoutPage extends StatefulWidget {
  final String plan; // 'monthly' | 'yearly'

  const CheckoutPage({super.key, required this.plan});

  /// Reutiliza el [SubscriptionBloc] ya creado por [SubscriptionPage] para
  /// que el estado (suscripcion activa, etc.) se comparta entre ambas
  /// pantallas sin volver a consultar el backend al regresar.
  static Future<void> push(BuildContext context, {required String plan}) {
    final bloc = context.read<SubscriptionBloc>();
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(value: bloc, child: CheckoutPage(plan: plan)),
      ),
    );
  }

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> with WidgetsBindingObserver {
  bool _waitingPaypal = false;

  SubscriptionPlanInfo get _planInfo => SubscriptionPlans.byId(widget.plan);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // MASVS-STORAGE: evita capturas de pantalla en esta vista de pago.
    ScreenSecurity.enable();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ScreenSecurity.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingPaypal) {
      _waitingPaypal = false;
      context.read<SubscriptionBloc>().add(const SubscriptionApprovalPollRequested());
    }
  }

  Future<void> _openApprovalPage(String approveUrl) async {
    final uri = Uri.tryParse(approveUrl);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened) {
      _waitingPaypal = true;
    } else if (mounted) {
      showSubscriptionSnack(context, 'No se pudo abrir PayPal. Intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pago Seguro'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionApprovalUrlReady) {
            _openApprovalPage(state.approveUrl);
          } else if (state is SubscriptionActionFailure) {
            showSubscriptionSnack(context, state.message);
          } else if (state is SubscriptionPollingTimedOut) {
            showSubscriptionSnack(
              context,
              'Verificando tu pago... puede tardar unos segundos.',
              isError: false,
            );
          }
        },
        builder: (context, state) {
          final activeSubscription = state is SubscriptionLoaded ? state.subscription : null;
          final justActivated = activeSubscription != null &&
              activeSubscription.isActive &&
              activeSubscription.planType == widget.plan;

          final Widget child;
          if (justActivated) {
            child = _buildSuccess(context);
          } else if (state is SubscriptionPolling) {
            child = _buildProcessing(
              icon: Icons.hourglass_top_rounded,
              title: 'Verificando tu pago...',
              subtitle: 'Esto puede tardar unos segundos. No cierres la aplicación.',
            );
          } else if (state is SubscriptionSubscribing || state is SubscriptionApprovalUrlReady) {
            child = _buildProcessing(
              icon: Icons.lock_clock_rounded,
              title: 'Conectando con PayPal...',
              subtitle: 'Te llevaremos a la página segura de PayPal para completar tu pago.',
            );
          } else {
            child = _buildPaymentForm(context, state);
          }

          return AnimatedSwitcher(duration: const Duration(milliseconds: 280), child: child);
        },
      ),
    );
  }

  // ==========================================
  // Formulario de pago
  // ==========================================

  Widget _buildPaymentForm(BuildContext context, SubscriptionState state) {
    return SafeArea(
      key: const ValueKey('form'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.huge,
          vertical: AppSpacing.xhuge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPlanTicket(),
            const SizedBox(height: AppSpacing.giant),
            Row(
              children: [
                const Icon(Icons.credit_card_rounded, size: 20, color: AppColors.onSurface),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Método de pago',
                  style: AppTypography.tituloMd.copyWith(color: AppColors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxlPlus),
            CardNumberField(onCardTypeChanged: (_) {}),
            const SizedBox(height: AppSpacing.xhuge),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.infoBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.lgXl),
                border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.infoBlue),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Text(
                      'Serás redirigido a PayPal para confirmar el pago de forma segura.',
                      style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xgiant),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => context
                    .read<SubscriptionBloc>()
                    .add(SubscriptionSubscribeRequested(plan: widget.plan)),
                icon: const Icon(Icons.lock_outline_rounded, color: AppColors.onPrimary),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
                ),
                label: const Text(
                  'Pagar con PayPal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta tipo "boleto" con el resumen del plan: icono, nombre, precio y
  /// los beneficios principales, para que el checkout se sienta como una
  /// compra premium y no como un formulario bancario.
  Widget _buildPlanTicket() {
    final plan = _planInfo;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.outlineVariant, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.huge,
              vertical: AppSpacing.xxxl,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.forestGreen],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.xxl),
                topRight: Radius.circular(AppRadius.xxl),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.lgXl),
                  ),
                  child: Icon(plan.icon, color: AppColors.onPrimary, size: 22),
                ),
                const SizedBox(width: AppSpacing.xxl),
                Expanded(
                  child: Text(
                    plan.title,
                    style: AppTypography.tituloMd.copyWith(color: AppColors.onPrimary),
                  ),
                ),
                Text(
                  plan.priceLabel,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.huge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incluye',
                  style: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...plan.features.take(3).map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.lg),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Estado de procesamiento
  // ==========================================

  Widget _buildProcessing({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      key: const ValueKey('processing'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.giant),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: AppSpacing.huge),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
            ),
            const SizedBox(height: AppSpacing.huge),
            Text(
              title,
              style: AppTypography.tituloMd.copyWith(color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              subtitle,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Pantalla de exito
  // ==========================================

  Widget _buildSuccess(BuildContext context) {
    return SafeArea(
      key: const ValueKey('success'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.huge,
          vertical: AppSpacing.xhuge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xgiant),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) => Transform.scale(scale: value, child: child),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.statusHealthyText,
                  size: 100,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xhuge),
            Text(
              '¡Pago Procesado\ncon Éxito!',
              style: AppTypography.tituloLg.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.giant),
            Container(
              padding: const EdgeInsets.all(AppSpacing.huge),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(AppRadius.xlPlus),
                border: Border.all(color: AppColors.outlineVariant, width: 0.5),
              ),
              child: Column(
                children: [
                  _buildReceiptRow('Plan adquirido', _planInfo.title, isHighlighted: true),
                  const Divider(height: AppSpacing.xhuge),
                  _buildReceiptRow('Monto pagado', _planInfo.priceLabel),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xgiantPlus),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
                ),
                child: const Text(
                  'Listo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onPrimary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.huge),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        ),
        const SizedBox(width: AppSpacing.xl),
        Text(
          value,
          style: AppTypography.labelMd.copyWith(
            color: isHighlighted ? AppColors.forestGreen : AppColors.onSurface,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
