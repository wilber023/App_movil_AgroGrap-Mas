// =============================================================================
// Core -- Seguridad de Pantalla (Anti-Screenshot)
// =============================================================================
// Capa: Core / Security
// MASVS-STORAGE: previene la fuga de datos sensibles deshabilitando
// capturas de pantalla y el thumbnail del selector de apps en pantallas
// que muestran credenciales (login/registro). En Android usa
// WindowManager.LayoutParams.FLAG_SECURE vía MethodChannel nativo
// (ver MainActivity.kt). iOS no expone un flag equivalente a nivel de
// sistema operativo: queda documentado como no soportado en esta etapa.
// =============================================================================

import 'package:flutter/services.dart';

abstract final class ScreenSecurity {
  static const MethodChannel _channel = MethodChannel('agrograph.mas/security');

  static Future<void> enable() async {
    try {
      await _channel.invokeMethod('enableSecureScreen');
    } on MissingPluginException {
      // Plataforma sin implementación nativa (ej. iOS/desktop): no-op.
    } on PlatformException {
      // No crítico para el flujo de la pantalla si falla.
    }
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod('disableSecureScreen');
    } on MissingPluginException {
      // Plataforma sin implementación nativa: no-op.
    } on PlatformException {
      // No crítico.
    }
  }
}
