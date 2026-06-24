import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../diagnosis/presentation/pages/diagnosis_page.dart';
import '../../../parcels/domain/entities/parcel_entity.dart';
import '../../../parcels/presentation/bloc/parcel_bloc.dart';
import '../../../subscription/presentation/pages/subscription_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPremiumBanner(context),
                    const SizedBox(height: 24),
                    _buildCameraActionCard(context),
                    const SizedBox(height: 24),
                    _buildMyParcelsSection(context),
                    const SizedBox(height: 24),
                    _buildRegionalAlertCard(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => curr is AuthAuthenticated || curr is AuthUnauthenticated,
      builder: (context, state) {
        final userName = state is AuthAuthenticated ? state.user.fullName : '';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: AppColors.forestGreen,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (userName.isNotEmpty)
                      Text(
                        userName,
                        style: AppTypography.etiquetaSm.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      'AgroGraph IA',
                      style: AppTypography.tituloMd.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 26,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionPage()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryContainer.withValues(alpha: 0.8),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.stars_rounded, color: AppColors.warmAmber, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'Obtén diagnósticos ilimitados y alertas avanzadas. '),
                    TextSpan(
                      text: 'Mejorar a Pro →',
                      style: AppTypography.etiquetaSm.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraActionCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DiagnosisPage()),
      ),
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 28),
            ),
            const Spacer(),
            Text(
              'Tomar foto del cultivo',
              style: AppTypography.tituloLg.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Diagnóstico en segundos · funciona sin señal',
              style: AppTypography.bodyMd.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyParcelsSection(BuildContext context) {
    return BlocBuilder<ParcelBloc, ParcelState>(
      builder: (context, state) {
        final parcels = state is ParcelLoaded ? state.parcels : <ParcelEntity>[];
        final isLoading = state is ParcelLoading || state is ParcelInitial;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mis Cultivos Activos',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (parcels.isNotEmpty)
                    Text(
                      '${parcels.length} ${parcels.length == 1 ? 'parcela' : 'parcelas'}',
                      style: AppTypography.etiquetaSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (isLoading)
                const SizedBox(
                  height: 48,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ),
                )
              else if (parcels.isEmpty)
                _buildEmptyParcels()
              else
                Column(
                  children: [
                    for (final p in parcels.take(3)) ...[
                      _buildParcelRow(p),
                      if (p != parcels.take(3).last)
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.outlineVariant.withValues(alpha: 0.4),
                        ),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyParcels() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF3DE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_florist_outlined, color: Color(0xFF52B788), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aún no tienes parcelas',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Registra tu primer cultivo en la pestaña Mis Parcelas',
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParcelRow(ParcelEntity p) {
    final statusColor = _statusColor(p.status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${p.cropName} · ${p.stageName}',
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              p.status,
              style: AppTypography.etiquetaSm.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionalAlertCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.burntOrange.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.burntOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                'ALERTA REGIONAL',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.burntOrange,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tizón tardío',
            style: AppTypography.tituloLg.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '3 km · 4 casos confirmados en tu zona',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Alerta':
        return AppColors.burntOrange;
      case 'Seguimiento':
        return AppColors.warmAmber;
      default:
        return AppColors.forestGreen;
    }
  }
}
