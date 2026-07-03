import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../login/auth/domain/entities/user_entity.dart';
import '../../../../login/auth/presentation/bloc/auth_bloc.dart';
import '../../../../login/auth/presentation/bloc/auth_event.dart';
import '../../../../login/auth/presentation/bloc/auth_state.dart';
import '../../../../login/auth/presentation/pages/select_profile_page.dart';
import '../../../offline/presentation/cubit/offline_cubit.dart';
import '../../../offline/presentation/pages/offline_mode_page.dart';
import '../../../../subscription/presentation/pages/subscription_page.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserHeader(context, user),
            const SizedBox(height: 32),

            _buildSectionTitle('MI CUENTA'),
            const SizedBox(height: 8),
            _buildListTile(
              title: 'Editar datos personales',
              icon: Icons.person_outline_rounded,
            ),
            _buildListTile(
              title: 'Región y cultivos',
              icon: Icons.layers_outlined,
            ),
            _buildListTile(
              title: 'Notificaciones y recordatorios',
              icon: Icons.notifications_none_rounded,
            ),
            _buildOfflineCard(context),
            const SizedBox(height: 32),

            _buildSectionTitle('SUSCRIPCIÓN'),
            const SizedBox(height: 8),
            _buildListTile(
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
            _buildListTile(
              title: 'Pausar suscripción',
              icon: Icons.pause_circle_outline_rounded,
            ),
            _buildListTile(
              title: 'Cancelar suscripción',
              icon: Icons.cancel_outlined,
              textColor: AppColors.error,
              iconColor: AppColors.error,
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('LEGAL Y PRIVACIDAD'),
            const SizedBox(height: 8),
            _buildExternalLinkTile('Política de privacidad'),
            _buildExternalLinkTile('Términos de uso'),
            _buildExternalLinkTile('Cómo manejamos tus datos'),
            const SizedBox(height: 32),

            _buildSectionTitle('ZONA DE PELIGRO'),
            const SizedBox(height: 8),
            _buildDangerZone(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Encabezado de usuario con datos reales del AuthBloc
  // ---------------------------------------------------------------------------
  Widget _buildUserHeader(BuildContext context, UserEntity user) {
    final initials = _getInitials(user.fullName.isNotEmpty
        ? user.fullName
        : user.username.isNotEmpty
            ? user.username
            : 'AG');

    final displayName =
        user.fullName.isNotEmpty ? user.fullName : user.username;
    final displaySub = user.email ?? user.phone ?? 'Agricultor';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusHealthyBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.forestGreen,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTypography.tituloMd.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displaySub,
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.outlineVariant, width: 0.5),
                  ),
                  child: Text(
                    'PLAN FREE',
                    style: AppTypography.etiquetaSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _goToSubscription(context),
            child: Text(
              'Mejorar a Pro →',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.burntOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Acceso rápido a "Diagnóstico sin Conexión" — solo navegación, sin toggle
  // ---------------------------------------------------------------------------
  Widget _buildOfflineCard(BuildContext context) {
    return BlocBuilder<OfflineCubit, OfflineState>(
      builder: (context, state) {
        final loaded = state is OfflineLoaded ? state : null;
        final isEnabled = loaded?.status.isOfflineModeEnabled ?? false;
        final downloaded = loaded?.status.downloadedCount ?? 0;
        final total = loaded?.status.totalAvailableCount ?? 0;

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppColors.forestGreen.withValues(alpha: 0.15)
                  : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              size: 20,
              color: isEnabled
                  ? AppColors.forestGreen
                  : AppColors.onSurfaceVariant,
            ),
          ),
          title: Text(
            'Diagnóstico sin Conexión',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          ),
          subtitle: Text(
            loaded != null
                ? (downloaded > 0
                    ? '$downloaded/$total guías · ${isEnabled ? "Modo activo" : "Modo inactivo"}'
                    : 'Gestiona recursos para uso sin internet')
                : 'Gestiona recursos para uso sin internet',
            style: AppTypography.etiquetaSm
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          trailing: const Icon(Icons.chevron_right_rounded,
              color: AppColors.outlineVariant, size: 20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OfflineModePage()),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        title,
        style: AppTypography.labelMd.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required IconData icon,
    String? subtitle,
    Color textColor = AppColors.onSurface,
    Color iconColor = AppColors.onSurfaceVariant,
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(
        title,
        style: AppTypography.bodyMd.copyWith(color: textColor),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTypography.etiquetaSm
                  .copyWith(color: AppColors.onSurfaceVariant),
            )
          : null,
      trailing: trailingWidget ??
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.outlineVariant, size: 20),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildExternalLinkTile(String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      title: Text(
        title,
        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
      ),
      trailing: const Icon(Icons.open_in_new_rounded,
          color: AppColors.outlineVariant, size: 20),
      onTap: () {},
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text(
              'Cerrar sesión',
              style: AppTypography.labelMd.copyWith(color: AppColors.error),
            ),
            onTap: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => const SelectProfilePage()),
                (route) => false,
              );
            },
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading:
                const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            title: Text(
              'Eliminar mi cuenta',
              style: AppTypography.labelMd.copyWith(color: AppColors.error),
            ),
            subtitle: Text(
              'Esta acción es permanente e irreversible',
              style: AppTypography.etiquetaSm.copyWith(color: AppColors.error),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _goToSubscription(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionPage()),
    );
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return 'AG';
  }
}

