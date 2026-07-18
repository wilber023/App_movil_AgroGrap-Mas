import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/subscription_bloc.dart';
import '../utils/subscription_snackbar.dart';
import '../widgets/subscription_content.dart';
import '../widgets/subscription_error_view.dart';
import '../widgets/subscription_loading_view.dart';

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
            SubscriptionInitial() || SubscriptionLoading() => const SubscriptionLoadingView(
                key: ValueKey('loading'),
              ),
            SubscriptionLoadFailure(:final message) => SubscriptionErrorView(
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
                child: SubscriptionContent(state: state),
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
