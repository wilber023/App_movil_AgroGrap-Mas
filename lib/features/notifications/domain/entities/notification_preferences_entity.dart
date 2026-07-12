import 'package:equatable/equatable.dart';

/// Preferencia de suscripcion configurada por el usuario en esta app,
/// persistida localmente para poder re-suscribir automaticamente cuando
/// cambia el token FCM o el usuario vuelve a iniciar sesion (ver
/// integrar_notificaciones.md, seccion 2.2 -- "volver a llamar este mismo
/// endpoint actualiza la suscripcion existente").
class NotificationPreferencesEntity extends Equatable {
  final bool enabled;
  final String estado;
  final List<String> cultivos;

  const NotificationPreferencesEntity({
    required this.enabled,
    required this.estado,
    this.cultivos = const [],
  });

  static const empty = NotificationPreferencesEntity(enabled: false, estado: '');

  @override
  List<Object?> get props => [enabled, estado, cultivos];
}
