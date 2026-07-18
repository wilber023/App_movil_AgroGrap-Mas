import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Mensaje mostrado cuando un filtro de la Agenda Agronómica no tiene
/// resultados (la lista completa no está vacía, solo el filtro aplicado).
class AgendaFilteredEmptyState extends StatelessWidget {
  const AgendaFilteredEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xgiant),
      child: Center(
        child: Text(
          'No hay tratamientos en este filtro.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Estado vacío de la Agenda Agronómica cuando no hay ningún tratamiento.
class AgendaEmptyView extends StatelessWidget {
  const AgendaEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.giant),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_note_outlined,
                size: 40,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: AppSpacing.huge),
            Text(
              'Sin tratamientos activos',
              style: AppTypography.tituloMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Realiza un diagnóstico de tu cultivo.\nCuando se detecte una enfermedad, aparecerá\naquí un plan de tratamiento automático.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado de error de la Agenda Agronómica (ej. sin conexión), con botón
/// de reintento.
class AgendaErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const AgendaErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.giant),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.offlineGrey),
            const SizedBox(height: AppSpacing.xxlPlus),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.huge),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
