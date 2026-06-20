import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/pages/select_profile_page.dart';

class AprendizProfilePage extends StatelessWidget {
  const AprendizProfilePage({super.key});

  void _onLogout(BuildContext context) {
    context.read<AuthBloc>().add(AuthLogoutRequested());
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SelectProfilePage()),
      (route) => false, // Elimina todas las rutas previas
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil (Aprendiz)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Pantalla Perfil - Aprendiz'),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _onLogout(context),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: Text(
                'Cerrar sesión',
                style: AppTypography.labelMd.copyWith(color: AppColors.error),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorContainer,
              ),
            )
          ],
        ),
      ),
    );
  }
}
