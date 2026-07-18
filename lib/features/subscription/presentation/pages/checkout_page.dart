import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/security/screen_security.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/subscription_bloc.dart';
import '../utils/subscription_plans.dart';
import '../utils/subscription_snackbar.dart';
import '../widgets/checkout_payment_form.dart';
import '../widgets/checkout_processing_view.dart';
import '../widgets/checkout_success_view.dart';

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
            child = CheckoutSuccessView(
              plan: _planInfo,
              onDone: () => Navigator.of(context).pop(),
            );
          } else if (state is SubscriptionPolling) {
            child = const CheckoutProcessingView(
              icon: Icons.hourglass_top_rounded,
              title: 'Verificando tu pago...',
              subtitle: 'Esto puede tardar unos segundos. No cierres la aplicación.',
            );
          } else if (state is SubscriptionSubscribing || state is SubscriptionApprovalUrlReady) {
            child = const CheckoutProcessingView(
              icon: Icons.lock_clock_rounded,
              title: 'Conectando con PayPal...',
              subtitle: 'Te llevaremos a la página segura de PayPal para completar tu pago.',
            );
          } else {
            child = CheckoutPaymentForm(
              plan: _planInfo,
              onPay: () => context
                  .read<SubscriptionBloc>()
                  .add(SubscriptionSubscribeRequested(plan: widget.plan)),
            );
          }

          return AnimatedSwitcher(duration: const Duration(milliseconds: 280), child: child);
        },
      ),
    );
  }
}
