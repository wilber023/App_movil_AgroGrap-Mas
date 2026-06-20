import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/pages/select_profile_page.dart';
import '../../../subscription/presentation/pages/subscription_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _offlineMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ENCABEZADO DEL USUARIO
            _buildUserHeader(context),
            const SizedBox(height: 32),

            // 2. SECCION "MI CUENTA"
            _buildSectionTitle('MI CUENTA'),
            const SizedBox(height: 8),
            _buildListTile(
              title: 'Editar datos personales',
              icon: Icons.person_outline_rounded,
            ),
            _buildListTile(
              title: 'Region y cultivos',
              icon: Icons.layers_outlined,
            ),
            _buildListTile(
              title: 'Notificaciones y recordatorios',
              icon: Icons.notifications_none_rounded,
            ),
            _buildSwitchTile(
              title: 'Modo sin conexion',
              icon: Icons.wifi_off_rounded,
              value: _offlineMode,
              onChanged: (val) {
                setState(() {
                  _offlineMode = val;
                });
              },
            ),
            _buildListTile(
              title: 'Almacenamiento local',
              icon: Icons.storage_rounded,
              subtitle: '24 MB \u00B7 3 en cola',
            ),
            const SizedBox(height: 32),

            // 3. SECCION "SUSCRIPCION"
            _buildSectionTitle('SUSCRIPCION'),
            const SizedBox(height: 8),
            _buildListTile(
              title: 'Mi plan actual: Free',
              icon: Icons.workspace_premium_outlined,
              trailingWidget: GestureDetector(
                onTap: () => _goToSubscription(context),
                child: Text(
                  'Ver Pro \u2192',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.burntOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _buildListTile(
              title: 'Pausar suscripcion',
              icon: Icons.pause_circle_outline_rounded,
            ),
            _buildListTile(
              title: 'Cancelar suscripcion',
              icon: Icons.cancel_outlined,
              textColor: AppColors.error,
              iconColor: AppColors.error,
            ),
            const SizedBox(height: 32),

            // 4. SECCION "LEGAL Y PRIVACIDAD"
            _buildSectionTitle('LEGAL Y PRIVACIDAD'),
            const SizedBox(height: 8),
            _buildExternalLinkTile('Politica de privacidad'),
            _buildExternalLinkTile('Terminos de uso'),
            _buildExternalLinkTile('Como manejamos tus datos'),
            const SizedBox(height: 32),

            // 5. SECCION "ZONA DE PELIGRO"
            _buildSectionTitle('ZONA DE PELIGRO'),
            const SizedBox(height: 8),
            _buildDangerZone(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Encabezado de usuario con tarjeta verde claro
  Widget _buildUserHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusHealthyBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Izquierda: Avatar
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.forestGreen,
            child: Text(
              'WH',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Centro: Informacion
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wil Hdz',
                  style: AppTypography.tituloMd.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chiapas \u00B7 3 parcelas activas',
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant, width: 0.5),
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

          // Derecha: Link a Pro
          GestureDetector(
            onTap: () => _goToSubscription(context),
            child: Text(
              'Mejorar a Pro \u2192',
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

  /// Titulo de seccion
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
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

  /// ListTile estandar
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
              style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
            )
          : null,
      trailing: trailingWidget ??
          const Icon(Icons.chevron_right_rounded, color: AppColors.outlineVariant, size: 20),
      onTap: onTap ?? () {},
    );
  }

  /// ListTile con Switch para modo offline
  Widget _buildSwitchTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      leading: Icon(icon, color: AppColors.onSurfaceVariant, size: 24),
      title: Text(
        title,
        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        thumbColor: WidgetStateProperty.all(Colors.white),
        activeTrackColor: Colors.blue, // Check azul segun instrucciones
      ),
    );
  }

  /// ListTile para enlaces externos
  Widget _buildExternalLinkTile(String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      title: Text(
        title,
        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
      ),
      trailing: const Icon(
        Icons.open_in_new_rounded,
        color: AppColors.outlineVariant,
        size: 20,
      ),
      onTap: () {},
    );
  }

  /// Zona de peligro (Container rojo)
  Widget _buildDangerZone(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text(
              'Cerrar sesion',
              style: AppTypography.labelMd.copyWith(color: AppColors.error),
            ),
            onTap: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SelectProfilePage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            title: Text(
              'Eliminar mi cuenta',
              style: AppTypography.labelMd.copyWith(color: AppColors.error),
            ),
            subtitle: Text(
              'Esta accion es permanente e irreversible',
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
}
