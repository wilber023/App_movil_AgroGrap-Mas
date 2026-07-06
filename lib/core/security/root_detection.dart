// =============================================================================
// Core -- Detección de Root / Jailbreak
// =============================================================================
// Capa: Core / Security
// MASVS-RESILIENCE: AgroGraph maneja datos económicos y agronómicos
// sensibles, por lo que se recomienda advertir al usuario si el
// dispositivo está rooteado (Android) o con jailbreak (iOS). Es una
// ADVERTENCIA, no un bloqueo: false positives en dispositivos de
// desarrollo/emuladores no deben impedir el uso de la app.
// =============================================================================

import 'package:safe_device/safe_device.dart';

abstract final class RootDetection {
  /// `true` si el dispositivo está rooteado/con jailbreak. En caso de que
  /// el chequeo nativo falle, se asume `false` (no bloquear al usuario).
  static Future<bool> isCompromised() async {
    try {
      return await SafeDevice.isJailBroken;
    } catch (_) {
      return false;
    }
  }
}
