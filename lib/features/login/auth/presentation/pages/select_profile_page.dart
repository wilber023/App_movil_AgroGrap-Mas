// =============================================================================
// Feature: Auth -- Pantalla de Seleccion de Perfil
// =============================================================================
// Capa: Presentation / Pages
// Logo + titulo + dos tarjetas seleccionables + link a login.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/profile_type.dart';
import '../bloc/auth_bloc.dart';
import 'login_page.dart';
import 'register_page.dart';

/// Pantalla de seleccion de perfil post-splash.
///
/// El usuario elige entre Agricultor y Aprendiz Agricola.
/// No hay boton back — es la primera pantalla real de la app.
class SelectProfilePage extends StatelessWidget {
  const SelectProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDs2,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xhuge),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xgiantPlus),
                // Logo y titulo
                _buildHeader(),
                const SizedBox(height: AppSpacing.xgiant),
                // Pregunta
                Text(
                  '¿Cómo quieres usar la app?',
                  style: AppTypography.headlineMd.copyWith(
                    color: AppColors.authHeaderTitle,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Puedes cambiar esto después desde tu perfil.',
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.authMutedSage,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.giant),
                // Tarjeta Agricultor
                _ProfileSelectorCard(
                  icon: Icons.agriculture_outlined,
                  iconColor: AppColors.authAgricultorAccent,
                  title: 'Agricultor',
                  description:
                      'Ya tengo parcelas y quiero diagnosticar problemas en mis cultivos.',
                  onTap: () => _navigateToRegister(context, ProfileType.agricultor),
                ),
                const SizedBox(height: AppSpacing.xxl),
                // Tarjeta Aprendiz Agricola
                _ProfileSelectorCard(
                  icon: Icons.spa_outlined,
                  iconColor: AppColors.warmAmber,
                  title: 'Aprendiz Agrícola',
                  description:
                      'Estoy empezando y quiero que la app me guíe paso a paso.',
                  onTap: () =>
                      _navigateToRegister(context, ProfileType.aprendizAgricola),
                ),
                const SizedBox(height: AppSpacing.xgiant),
                // Link a login
                _buildLoginLink(context),
                const SizedBox(height: AppSpacing.giant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.forestGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.eco_rounded,
            size: 34,
            color: AppColors.forestGreen,
          ),
        ),
        const SizedBox(height: AppSpacing.xxlPlus),
        Text(
          'AgroGraph-MAS',
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.forestGreen,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _navigateToRegister(BuildContext context, ProfileType profileType) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => GetIt.instance<AuthBloc>(),
          child: RegisterPage(profileType: profileType),
        ),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider(
              create: (_) => GetIt.instance<AuthBloc>(),
              child: const LoginPage(),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: RichText(
          text: TextSpan(
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.authMutedSage,
              fontSize: 13,
            ),
            children: [
              const TextSpan(text: 'Ya tengo cuenta — '),
              TextSpan(
                text: 'Iniciar sesión',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.authAgricultorAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta reutilizable para seleccionar un tipo de perfil.
///
/// Componente aislado para respetar OCP — si se agrega un tercer perfil,
/// solo se instancia una nueva _ProfileSelectorCard.
class _ProfileSelectorCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ProfileSelectorCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.onPrimary,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xxlPlus),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.cardBorder,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              // Icono
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.lgXl),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.xxl),
              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.authHeaderTitle,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: AppTypography.etiquetaSm.copyWith(
                        color: AppColors.authMutedSage,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Chevron
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.offlineGrey,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
