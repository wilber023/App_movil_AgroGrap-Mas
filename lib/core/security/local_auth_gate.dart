// =============================================================================
// Core -- Puerta de Autenticación Local (Biometría / PIN)
// =============================================================================
// Capa: Core / Security (consumido desde presentation/)
// MASVS-AUTH: refuerza operaciones sensibles (ej. eliminar una parcela)
// con una confirmación biométrica adicional, en vez de un PIN propio
// guardado en texto plano. Si el dispositivo no tiene biometría/PIN
// configurado, o el chequeo falla, se deja pasar (fail-open) para no
// bloquear al usuario: la confirmación de UI que ya precede a la llamada
// sigue siendo la barrera principal.
// =============================================================================

import 'package:local_auth/local_auth.dart';

class LocalAuthGate {
  final LocalAuthentication _auth;

  LocalAuthGate({LocalAuthentication? auth}) : _auth = auth ?? LocalAuthentication();

  Future<bool> authenticate({
    String localizedReason = 'Confirma tu identidad para continuar',
  }) async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!isSupported && !canCheckBiometrics) return true;

      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } catch (_) {
      // No se pudo evaluar autenticación local en este dispositivo: no
      // bloquea la operación (fail-open), la confirmación de UI ya
      // mostrada sigue siendo la barrera principal.
      return true;
    }
  }
}
