// =============================================================================
// Feature: Auth -- Pantalla de Seleccion de Perfil
// =============================================================================
// Capa: Presentation / Pages
// Logo + titulo + dos tarjetas seleccionables + link a login.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                // Logo y titulo
                _buildHeader(),
                const SizedBox(height: 40),
                // Pregunta
                Text(
                  '¿Cómo quieres usar la app?',
                  style: AppTypography.headlineMd.copyWith(
                    color: const Color(0xFF1B2D27),
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Puedes cambiar esto después desde tu perfil.',
                  style: AppTypography.etiquetaSm.copyWith(
                    color: const Color(0xFF6B8F71),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Tarjeta Agricultor
                _ProfileSelectorCard(
                  icon: Icons.agriculture_outlined,
                  iconColor: const Color(0xFF2E7D32),
                  title: 'Agricultor',
                  description:
                      'Ya tengo parcelas y quiero diagnosticar problemas en mis cultivos.',
                  onTap: () => _navigateToRegister(context, ProfileType.agricultor),
                ),
                const SizedBox(height: 14),
                // Tarjeta Aprendiz Agricola
                _ProfileSelectorCard(
                  icon: Icons.spa_outlined,
                  iconColor: const Color(0xFFF4A261),
                  title: 'Aprendiz Agrícola',
                  description:
                      'Estoy empezando y quiero que la app me guíe paso a paso.',
                  onTap: () =>
                      _navigateToRegister(context, ProfileType.aprendizAgricola),
                ),
                const SizedBox(height: 40),
                // Link a login
                _buildLoginLink(context),
                const SizedBox(height: 32),
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
        const SizedBox(height: 16),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: RichText(
          text: TextSpan(
            style: AppTypography.etiquetaSm.copyWith(
              color: const Color(0xFF6B8F71),
              fontSize: 13,
            ),
            children: [
              const TextSpan(text: 'Ya tengo cuenta — '),
              TextSpan(
                text: 'Iniciar sesión',
                style: AppTypography.labelMd.copyWith(
                  color: const Color(0xFF2E7D32),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelMd.copyWith(
                        color: const Color(0xFF1B2D27),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.etiquetaSm.copyWith(
                        color: const Color(0xFF6B8F71),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Chevron
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFADB5BD),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
