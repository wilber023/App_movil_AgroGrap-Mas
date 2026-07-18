import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/notification_history_cubit.dart';
import '../widgets/notification_history_tile.dart';

/// Historial de notificaciones push recibidas -- pantalla compartida entre
/// Agricultor y Aprendiz (misma pantalla, mismo componente para ambos
/// roles). El historial es 100% local: el backend de notificaciones no
/// expone ningun endpoint para recuperar mensajes pasados (ver
/// integrar_notificaciones.md), solo suscripcion.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => sl<NotificationHistoryCubit>()..load(),
        child: const NotificationsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDs2,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        title: Text(
          'Notificaciones',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: BlocBuilder<NotificationHistoryCubit, NotificationHistoryState>(
        builder: (context, state) {
          return switch (state) {
            NotificationHistoryLoading() => const Center(
                child: CircularProgressIndicator(color: AppColors.forestGreen),
              ),
            NotificationHistoryError(:final message) => _ErrorState(
                message: message,
                onRetry: () => context.read<NotificationHistoryCubit>().load(),
              ),
            NotificationHistoryLoaded(:final items) => items.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
                    color: AppColors.forestGreen,
                    onRefresh: () => context.read<NotificationHistoryCubit>().load(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.xl,
                        bottom: AppSpacing.xhuge,
                      ),
                      itemCount: items.length,
                      itemBuilder: (_, i) => NotificationHistoryTile(entry: items[i]),
                    ),
                  ),
          };
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.giant),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.statusHealthyBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.forestGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.xxlPlus),
            Text(
              'Aún no tienes notificaciones',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aquí aparecerán las alertas fitosanitarias que recibas en este dispositivo. '
              'Actívalas desde "Notificaciones" en tu perfil.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.giant),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 32),
            const SizedBox(height: AppSpacing.xl),
            Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxlPlus),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen),
              child: const Text('Reintentar', style: TextStyle(color: AppColors.onPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}
