import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../login/auth/presentation/bloc/auth_bloc.dart';
import '../../../../login/auth/presentation/bloc/auth_event.dart';
import '../../../../login/auth/presentation/bloc/auth_state.dart';
import '../../../../login/auth/presentation/pages/select_profile_page.dart';
import '../../../../notifications/presentation/pages/notification_settings_page.dart';
import '../../../../clustering/presentation/pages/epidemiological_map_page.dart';
import '../../../agenda/agenda.dart';
import '../../../cultivo/cultivo.dart';
import '../../../diagnostico/diagnostico.dart';
import '../../domain/entities/aprendiz_recommendation_entity.dart';
import '../bloc/aprendiz_profile_bloc.dart';
import '../widgets/profile_activity_summary_card.dart';
import '../widgets/profile_avatar_header.dart';
import '../widgets/profile_danger_zone.dart';
import '../widgets/profile_recommendation_card.dart';
import '../widgets/profile_section_header.dart';
import '../widgets/profile_settings_card.dart';
import '../widgets/profile_settings_row.dart';
import '../widgets/profile_top_bar.dart';

class AprendizProfilePage extends StatelessWidget {
  const AprendizProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AprendizProfileBloc>()..add(const ProfileOverviewRequested()),
      child: const _AprendizProfileView(),
    );
  }
}

class _AprendizProfileView extends StatelessWidget {
  const _AprendizProfileView();

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
        child: CircularProgressIndicator(color: AppColors.aSecondary),
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

  void _deleteAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar cuenta?'),
        content: const Text('Esta acción es permanente e irreversible. Todos tus datos serán eliminados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _handleRecommendationAction(BuildContext context, RecommendationAction action) {
    final Widget? target = switch (action) {
      RecommendationAction.registerCrop => const AprendizCropRegisterPage(),
      RecommendationAction.diagnosis => const DiagnosisEntryAprendizPage(),
      RecommendationAction.agenda => const AprendizAgendaPage(),
      RecommendationAction.none => null,
    };
    if (target == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => target));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aSurface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ProfileTopBar(),
            Expanded(
              child: BlocBuilder<AprendizProfileBloc, AprendizProfileState>(
                builder: (context, state) {
                  if (state is ProfileFailure) {
                    return _ErrorContent(
                      message: state.message,
                      onRetry: () => context.read<AprendizProfileBloc>().add(const ProfileOverviewRequested()),
                    );
                  }
                  if (state is! ProfileLoaded) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.aSecondary));
                  }

                  final overview = state.overview;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxlPlus,
                      AppSpacing.xhuge,
                      AppSpacing.xxlPlus,
                      AppSpacing.colossal,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileAvatarHeader(
                          initials: overview.userInitials,
                          name: overview.userName,
                          email: overview.email,
                        ),
                        const SizedBox(height: AppSpacing.huge),

                        // ── Resumen de actividad ──────────────────────
                        ProfileActivitySummaryCard(summary: overview.activitySummary),
                        const SizedBox(height: AppSpacing.xxlPlus),

                        // ── Recomendación personalizada ───────────────
                        ProfileRecommendationCard(
                          recommendation: overview.recommendation,
                          onAction: overview.recommendation.action == RecommendationAction.none
                              ? null
                              : () => _handleRecommendationAction(context, overview.recommendation.action),
                        ),
                        const SizedBox(height: AppSpacing.xxhuge),

                        // ── MI CUENTA ──────────────────────────────────
                        const ProfileSectionHeader(label: 'MI CUENTA'),
                        const SizedBox(height: AppSpacing.md),
                        ProfileSettingsCard(
                          children: [
                            ProfileSettingsRow(
                              icon: Icons.notifications_outlined,
                              label: 'Notificaciones',
                              isFirst: true,
                              onTap: () => Navigator.push(context, NotificationSettingsPage.route()),
                            ),
                            const ProfileRowDivider(),
                            ProfileSettingsRow(
                              icon: Icons.map_outlined,
                              label: 'Mapa epidemiológico',
                              isLast: true,
                              onTap: () => Navigator.push(context, EpidemiologicalMapPage.route()),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.huge),

                        // ── LEGAL Y PRIVACIDAD ─────────────────────────
                        const ProfileSectionHeader(label: 'LEGAL Y PRIVACIDAD'),
                        const SizedBox(height: AppSpacing.md),
                        ProfileSettingsCard(
                          children: [
                            ProfileSettingsRow(
                              icon: Icons.shield_outlined,
                              label: 'Política de privacidad',
                              trailingIcon: Icons.open_in_new,
                              isFirst: true,
                              onTap: () {},
                            ),
                            const ProfileRowDivider(),
                            ProfileSettingsRow(
                              icon: Icons.description_outlined,
                              label: 'Términos de uso',
                              trailingIcon: Icons.open_in_new,
                              onTap: () {},
                            ),
                            const ProfileRowDivider(),
                            ProfileSettingsRow(
                              icon: Icons.data_usage_outlined,
                              label: 'Cómo manejamos tus datos',
                              trailingIcon: Icons.open_in_new,
                              isLast: true,
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.huge),

                        // ── ZONA DE PELIGRO ────────────────────────────
                        ProfileDangerZone(
                          onLogout: () => _logout(context),
                          onDeleteAccount: () => _deleteAccount(context),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorContent({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xhuge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 32),
            const SizedBox(height: AppSpacing.xl),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xxlPlus),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
