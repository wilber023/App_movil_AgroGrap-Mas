import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../login/auth/presentation/bloc/auth_bloc.dart';
import '../../../login/auth/presentation/bloc/auth_event.dart';
import '../../../login/auth/presentation/pages/select_profile_page.dart';

class AprendizProfilePage extends StatefulWidget {
  const AprendizProfilePage({super.key});

  @override
  State<AprendizProfilePage> createState() => _AprendizProfilePageState();
}

class _AprendizProfilePageState extends State<AprendizProfilePage> {
  bool _offlineMode = true;

  void _logout() {
    context.read<AuthBloc>().add(AuthLogoutRequested());
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SelectProfilePage()),
      (route) => false,
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar cuenta?'),
        content: const Text(
            'Esta acción es permanente e irreversible. Todos tus datos serán eliminados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aSurface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // TopAppBar
            Container(
              color: AppColors.aPrimaryContainer,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.wifi_off, color: Colors.white),
                    onPressed: () {},
                  ),
                  const Expanded(
                    child: Text(
                      'Perfil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── User card ──────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: AppColors.aPrimaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'WH',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Wil Hdz',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.aOnSurface),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Chiapas - 3 parcelas activas',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.aOnSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.aSecondaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'PLAN FREE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.aOnSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.05,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              GestureDetector(
                                onTap: () {},
                                child: const Text(
                                  'Mejorar a Pro →',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.aOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── MI CUENTA ──────────────────────────────────────
                    const _SectionHeader(label: 'MI CUENTA'),
                    const SizedBox(height: 8),
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          icon: Icons.person_outline,
                          label: 'Editar datos personales',
                          isFirst: true,
                          onTap: () {},
                        ),
                        const _RowDivider(),
                        _SettingsRow(
                          icon: Icons.location_on_outlined,
                          label: 'Región y cultivos',
                          onTap: () {},
                        ),
                        const _RowDivider(),
                        _SettingsRow(
                          icon: Icons.notifications_outlined,
                          label: 'Notificaciones y recordatorios',
                          onTap: () {},
                        ),
                        const _RowDivider(),
                        // Toggle row
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.wifi_off_outlined,
                                  color: AppColors.aOnSurfaceVariant, size: 22),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Text(
                                  'Modo sin conexión',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.aOnSurface),
                                ),
                              ),
                              Switch(
                                value: _offlineMode,
                                onChanged: (v) =>
                                    setState(() => _offlineMode = v),
                                activeThumbColor: AppColors.aSecondary,
                                activeTrackColor: AppColors.aSecondaryContainer,
                              ),
                            ],
                          ),
                        ),
                        const _RowDivider(),
                        _SettingsRow(
                          icon: Icons.storage_outlined,
                          label: 'Almacenamiento local',
                          trailing: '24 MB · 3 en cola',
                          isLast: true,
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── SUSCRIPCIÓN ────────────────────────────────────
                    const _SectionHeader(label: 'SUSCRIPCIÓN'),
                    const SizedBox(height: 8),
                    _SettingsCard(
                      children: [
                        // Plan row
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.workspace_premium_outlined,
                                  color: AppColors.aOnSurfaceVariant, size: 22),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Text(
                                  'Mi plan actual: Free',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.aOnSurface),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: const Text(
                                  'Ver Pro →',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.aOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const _RowDivider(),
                        _SettingsRow(
                          icon: Icons.pause_circle_outline,
                          label: 'Pausar suscripción',
                          onTap: () {},
                        ),
                        const _RowDivider(),
                        _SettingsRow(
                          icon: Icons.cancel_outlined,
                          label: 'Cancelar suscripción',
                          iconColor: AppColors.error,
                          isLast: true,
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── LEGAL Y PRIVACIDAD ─────────────────────────────
                    const _SectionHeader(label: 'LEGAL Y PRIVACIDAD'),
                    const SizedBox(height: 8),
                    _SettingsCard(
                      children: [
                        _SettingsRow(
                          icon: Icons.shield_outlined,
                          label: 'Política de privacidad',
                          trailingIcon: Icons.open_in_new,
                          isFirst: true,
                          onTap: () {},
                        ),
                        const _RowDivider(),
                        _SettingsRow(
                          icon: Icons.description_outlined,
                          label: 'Términos de uso',
                          trailingIcon: Icons.open_in_new,
                          onTap: () {},
                        ),
                        const _RowDivider(),
                        _SettingsRow(
                          icon: Icons.data_usage_outlined,
                          label: 'Cómo manejamos tus datos',
                          trailingIcon: Icons.open_in_new,
                          isLast: true,
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── ZONA DE PELIGRO ────────────────────────────────
                    const Text(
                      'ZONA DE PELIGRO',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.aSurfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          // Cerrar sesión
                          InkWell(
                            onTap: _logout,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  const Icon(Icons.logout,
                                      color: AppColors.error, size: 22),
                                  const SizedBox(width: 14),
                                  const Text(
                                    'Cerrar sesión',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: 52,
                            color: AppColors.error.withValues(alpha: 0.2),
                          ),
                          // Eliminar cuenta
                          InkWell(
                            onTap: _deleteAccount,
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline,
                                      color: AppColors.error, size: 22),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Eliminar mi cuenta',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Esta acción es permanente e irreversible',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.error
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.aOnSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.aOutlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final IconData? trailingIcon;
  final Color? iconColor;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.trailingIcon,
    this.iconColor,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(12) : Radius.zero,
        bottom: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                color: iconColor ?? AppColors.aOnSurfaceVariant, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style:
                    const TextStyle(fontSize: 15, color: AppColors.aOnSurface),
              ),
            ),
            if (trailing != null) ...[
              Text(trailing!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.aOnSurfaceVariant)),
              const SizedBox(width: 8),
            ],
            Icon(
              trailingIcon ?? Icons.chevron_right,
              color: AppColors.aOnSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 52,
      color: AppColors.aOutlineVariant,
    );
  }
}
