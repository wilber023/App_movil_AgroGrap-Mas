// =============================================================================
// Core -- Mecanismo de Actualización Forzada
// =============================================================================
// Capa: Core / Security (presentation/startup lo invoca al iniciar la app)
// MASVS-CODE: compara la versión instalada contra una versión mínima
// devuelta por el backend y permite bloquear el uso con un diálogo si
// está desactualizada. Usa comparación semántica real (pub_semver) en vez
// de `String.compareTo`, que falla con versiones de más de un dígito
// (ej. "1.9.0" vs "1.10.0").
//
// Nota: el backend de AgroGraph aún no expone un endpoint de versión
// mínima, por lo que [minSupportedVersion] apunta a la versión actual del
// pubspec (nunca bloquea todavía). En cuanto exista el endpoint, basta
// con reemplazar ese valor por la respuesta remota.
// =============================================================================

import 'package:pub_semver/pub_semver.dart';

abstract final class ForceUpdateGate {
  /// TODO(backend): reemplazar por el valor devuelto por el endpoint de
  /// versión mínima cuando el backend lo exponga.
  static const String minSupportedVersion = '1.0.0';

  static bool needsUpdate(String currentVersion, {String? minVersion}) {
    final current = Version.parse(_stripBuildNumber(currentVersion));
    final min = Version.parse(_stripBuildNumber(minVersion ?? minSupportedVersion));
    return current < min;
  }

  static String _stripBuildNumber(String version) => version.split('+').first;
}
