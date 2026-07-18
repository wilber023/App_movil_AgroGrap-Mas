import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../login/auth/domain/entities/user_entity.dart';
import '../../../../login/auth/presentation/bloc/auth_bloc.dart';
import '../../../../login/auth/presentation/bloc/auth_event.dart';
import '../../../../login/auth/presentation/bloc/auth_state.dart';
import '../../../../login/auth/presentation/pages/select_profile_page.dart';
import '../../../../notifications/presentation/pages/notification_settings_page.dart';
import '../../../../clustering/presentation/pages/epidemiological_map_page.dart';
import '../../../../subscription/presentation/pages/subscription_page.dart';
import '../widgets/profile_danger_zone.dart';
import '../widgets/profile_list_tiles.dart';
import '../widgets/profile_offline_card.dart';
import '../widgets/profile_user_header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated
            ? authState.user
            : UserEntity.empty;
        return _ProfileScaffold(user: user);
      },
    );
  }
}

class _ProfileScaffold extends StatelessWidget {
  final UserEntity user;
  const _ProfileScaffold({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.xxlPlus),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileUserHeader(user: user, onUpgradeTap: () => _goToSubscription(context)),
            const SizedBox(height: AppSpacing.giant),

            const ProfileSectionTitle('MI CUENTA'),
            const SizedBox(height: AppSpacing.md),
            const ProfileListTile(
              title: 'Editar datos personales',
              icon: Icons.person_outline_rounded,
            ),
            const ProfileListTile(
              title: 'Región y cultivos',
              icon: Icons.layers_outlined,
            ),
            ProfileListTile(
              title: 'Notificaciones y recordatorios',
              icon: Icons.notifications_none_rounded,
              onTap: () => Navigator.push(context, NotificationSettingsPage.route()),
            ),
            ProfileListTile(
              title: 'Mapa epidemiológico',
              icon: Icons.map_outlined,
              onTap: () => Navigator.push(context, EpidemiologicalMapPage.route()),
            ),
            const ProfileOfflineCard(),
            const SizedBox(height: AppSpacing.giant),

            const ProfileSectionTitle('SUSCRIPCIÓN'),
            const SizedBox(height: AppSpacing.md),
            ProfileListTile(
              title: 'Mi plan actual: Free',
              icon: Icons.workspace_premium_outlined,
              trailingWidget: GestureDetector(
                onTap: () => _goToSubscription(context),
                child: Text(
                  'Ver Pro →',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.burntOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const ProfileListTile(
              title: 'Pausar suscripción',
              icon: Icons.pause_circle_outline_rounded,
            ),
            const ProfileListTile(
              title: 'Cancelar suscripción',
              icon: Icons.cancel_outlined,
              textColor: AppColors.error,
              iconColor: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.giant),

            const ProfileSectionTitle('LEGAL Y PRIVACIDAD'),
            const SizedBox(height: AppSpacing.md),
            const ProfileExternalLinkTile('Política de privacidad'),
            const ProfileExternalLinkTile('Términos de uso'),
            const ProfileExternalLinkTile('Cómo manejamos tus datos'),
            const SizedBox(height: AppSpacing.giant),

            const ProfileSectionTitle('ZONA DE PELIGRO'),
            const SizedBox(height: AppSpacing.md),
            ProfileDangerZone(onLogout: () => _logout(context)),
            const SizedBox(height: AppSpacing.xgiant),
          ],
        ),
      ),
    );
  }

  void _goToSubscription(BuildContext context) {
    Navigator.push(context, SubscriptionPage.route());
  }

  /// Espera a que el logout realmente termine (exito o fallo) antes de
  /// navegar, para no dejar una carrera entre el Navigator y la limpieza
  /// de sesion (Hive + TokenStorage) que dispara AuthLogoutRequested.
  Future<void> _logout(BuildContext context) async {
    final bloc = context.read<AuthBloc>();
    bloc.add(const AuthLogoutRequested());

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.forestGreen),
      ),
    );

    await bloc.stream.firstWhere(
      (state) => state is AuthUnauthenticated || state is AuthFailureState,
    );

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SelectProfilePage()),
      (route) => false,
    );
  }
}
