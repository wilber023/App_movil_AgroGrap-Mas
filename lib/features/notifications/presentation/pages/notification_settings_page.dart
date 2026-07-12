import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/notification_preferences_entity.dart';
import '../bloc/notification_subscription_bloc.dart';

/// Preferencias de alertas push -- pantalla compartida entre Agricultor y
/// Aprendiz (misma pantalla, mismo componente para ambos roles).
///
/// El backend de notificaciones suscribe por `estado` (entidad federativa) y
/// opcionalmente `cultivos` (ver integrar_notificaciones.md, seccion 2.2).
/// La app no tiene hoy un catalogo confiable de estados/mapa epidemiologico
/// integrado, asi que el usuario los escribe el mismo una sola vez; a partir
/// de ahi la app reintenta la suscripcion automaticamente en cada login o
/// cuando cambia el token FCM (ver NotificationsBootstrap).
class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => sl<NotificationSubscriptionBloc>()
          ..add(const NotificationPreferencesRequested()),
        child: const NotificationSettingsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDs2,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notificaciones',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: BlocConsumer<NotificationSubscriptionBloc, NotificationSubscriptionState>(
        listener: (context, state) {
          if (state is NotificationSubscriptionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is NotificationSubscriptionInitial || state is NotificationSubscriptionLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.forestGreen));
          }
          final prefs = switch (state) {
            NotificationSubscriptionLoaded(:final preferences) => preferences,
            NotificationSubscriptionSaving(:final preferences) => preferences,
            NotificationSubscriptionFailure(:final preferences) => preferences,
            _ => null,
          }!;
          final saving = state is NotificationSubscriptionSaving;
          return _SettingsForm(preferences: prefs, saving: saving);
        },
      ),
    );
  }
}

class _SettingsForm extends StatefulWidget {
  final NotificationPreferencesEntity preferences;
  final bool saving;

  const _SettingsForm({required this.preferences, required this.saving});

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  late bool _enabled;
  late final TextEditingController _estadoController;
  late final TextEditingController _cultivoController;
  late List<String> _cultivos;

  @override
  void initState() {
    super.initState();
    _enabled = widget.preferences.enabled;
    _estadoController = TextEditingController(text: widget.preferences.estado);
    _cultivoController = TextEditingController();
    _cultivos = List<String>.from(widget.preferences.cultivos);
  }

  @override
  void didUpdateWidget(covariant _SettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences != widget.preferences) {
      _enabled = widget.preferences.enabled;
      if (_estadoController.text.isEmpty) {
        _estadoController.text = widget.preferences.estado;
      }
      _cultivos = List<String>.from(widget.preferences.cultivos);
    }
  }

  @override
  void dispose() {
    _estadoController.dispose();
    _cultivoController.dispose();
    super.dispose();
  }

  void _addCultivo() {
    final value = _cultivoController.text.trim();
    if (value.isEmpty || _cultivos.contains(value)) return;
    setState(() {
      _cultivos.add(value);
      _cultivoController.clear();
    });
  }

  void _save() {
    if (_enabled) {
      final estado = _estadoController.text.trim();
      if (estado.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escribe el estado para el que quieres recibir alertas.')),
        );
        return;
      }
      context.read<NotificationSubscriptionBloc>().add(
            NotificationSubscribeRequested(estado: estado, cultivos: _cultivos),
          );
    } else {
      context.read<NotificationSubscriptionBloc>().add(const NotificationUnsubscribeRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recibir alertas fitosanitarias',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                    ),
                  ),
                  Switch(
                    value: _enabled,
                    activeThumbColor: AppColors.forestGreen,
                    onChanged: widget.saving ? null : (v) => setState(() => _enabled = v),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Te avisamos cuando cambie la campaña fitosanitaria activa en tu estado.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              if (_enabled) ...[
                const SizedBox(height: 16),
                Text('Estado', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                const SizedBox(height: 6),
                TextField(
                  controller: _estadoController,
                  enabled: !widget.saving,
                  decoration: InputDecoration(
                    hintText: 'Ej. Sinaloa',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Cultivos (opcional)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                const SizedBox(height: 4),
                Text(
                  'Si no agregas ninguno, recibirás todas las alertas de tu estado.',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cultivoController,
                        enabled: !widget.saving,
                        decoration: InputDecoration(
                          hintText: 'Ej. Maíz',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onSubmitted: (_) => _addCultivo(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: widget.saving ? null : _addCultivo,
                      icon: const Icon(Icons.add_circle, color: AppColors.forestGreen),
                    ),
                  ],
                ),
                if (_cultivos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _cultivos
                        .map((c) => Chip(
                              label: Text(c, style: GoogleFonts.inter(fontSize: 11)),
                              onDeleted: widget.saving ? null : () => setState(() => _cultivos.remove(c)),
                              backgroundColor: AppColors.surfaceContainerHigh,
                            ))
                        .toList(),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: widget.saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: widget.saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text('Guardar', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
