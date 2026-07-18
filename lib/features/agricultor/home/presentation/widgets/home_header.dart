import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../login/auth/presentation/bloc/auth_bloc.dart';
import '../../../../login/auth/presentation/bloc/auth_state.dart';
import '../../../../notifications/presentation/pages/notifications_page.dart';
import '../bloc/home_bloc.dart';
import 'home_helpers.dart';

/// Encabezado de HomePage: saludo personalizado, título de la app y campana
/// de notificaciones con indicador de no leídas.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => curr is AuthAuthenticated || curr is AuthUnauthenticated,
      builder: (context, authState) {
        final fullName = authState is AuthAuthenticated ? authState.user.fullName : '';
        final name = homeFirstName(fullName);

        return BlocBuilder<HomeBloc, HomeState>(
          builder: (context, homeState) {
            final dashboard = homeState is HomeLoaded ? homeState.dashboard : null;
            final hasUnread = dashboard?.recentAlerts.any((a) => !a.isRead) ?? false;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxlPlus,
                AppSpacing.xxl,
                AppSpacing.xxlPlus,
                AppSpacing.xxxl,
              ),
              color: AppColors.forestGreen,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name.isEmpty ? homeGreeting() : '${homeGreeting()}, $name 👋',
                          style: AppTypography.etiquetaSm.copyWith(
                            color: AppColors.onPrimary.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'AgroGraph IA',
                          style: AppTypography.tituloLg.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Tu asistente agrícola inteligente',
                          style: AppTypography.etiquetaSm.copyWith(
                            color: AppColors.onPrimary.withValues(alpha: 0.75),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  GestureDetector(
                    onTap: () => Navigator.push(context, NotificationsPage.route()),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.onPrimary,
                          size: 26,
                        ),
                        if (hasUnread)
                          Positioned(
                            right: -1,
                            top: -1,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.forestGreen, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
