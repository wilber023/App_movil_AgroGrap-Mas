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

  /// `true` cuando la preferencia ya se guardó localmente pero la
  /// suscripción/cancelación push remota (`POST/DELETE /suscripciones`,
  /// microservicio en `3.218.172.128:8100`) todavía no se confirmó -- por
  /// timeout, falta de red, o que aún no se intentó. El guardado local
  /// (lo único que necesita el banner de alerta de Inicio) nunca depende de
  /// este valor. Mismo patrón que `AgendaActivityEntity.isPendingSync`.
  final bool pushSyncPending;

  const NotificationPreferencesEntity({
    required this.enabled,
    required this.estado,
    this.cultivos = const [],
    this.pushSyncPending = false,
  });

  static const empty = NotificationPreferencesEntity(enabled: false, estado: '');

  NotificationPreferencesEntity copyWith({
    bool? enabled,
    String? estado,
    List<String>? cultivos,
    bool? pushSyncPending,
  }) {
    return NotificationPreferencesEntity(
      enabled: enabled ?? this.enabled,
      estado: estado ?? this.estado,
      cultivos: cultivos ?? this.cultivos,
      pushSyncPending: pushSyncPending ?? this.pushSyncPending,
    );
  }

  @override
  List<Object?> get props => [enabled, estado, cultivos, pushSyncPending];
}
