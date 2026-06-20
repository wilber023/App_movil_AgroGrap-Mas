// =============================================================================
// Feature: Auth -- Modelo de Dominio: Tipo de Perfil
// =============================================================================
// Capa: Domain / Entities
// Modelo sellado extensible (OCP) — agregar un tercer perfil futuro
// no requiere modificar el codigo de seleccion existente.
// =============================================================================

/// Tipos de perfil disponibles en AgroGraph-MAS.
///
/// Cada tipo determina el flujo post-autenticacion:
/// - [agricultor]: navega al dashboard con parcelas y diagnosticos.
/// - [aprendizAgricola]: navega al flujo de aprendizaje guiado (pendiente).
enum ProfileType {
  agricultor,
  aprendizAgricola;

  /// Nombre legible para la UI (en espanol).
  String get displayName {
    switch (this) {
      case ProfileType.agricultor:
        return 'Agricultor';
      case ProfileType.aprendizAgricola:
        return 'Aprendiz Agrícola';
    }
  }

  /// Clave para serializacion y persistencia local.
  String get key {
    switch (this) {
      case ProfileType.agricultor:
        return 'agricultor';
      case ProfileType.aprendizAgricola:
        return 'aprendiz_agricola';
    }
  }

  /// Deserializa desde la clave guardada en Hive.
  static ProfileType? fromKey(String key) {
    switch (key) {
      case 'agricultor':
        return ProfileType.agricultor;
      case 'aprendiz_agricola':
        return ProfileType.aprendizAgricola;
      default:
        return null;
    }
  }
}

/// Resultado sellado de navegacion post-autenticacion.
///
/// El dominio decide el destino; la UI solo reacciona.
sealed class AuthDestination {
  const AuthDestination();
}

/// Navegar al MainShell existente del Agricultor.
final class NavigateToAgricultorHome extends AuthDestination {
  const NavigateToAgricultorHome();
}

/// El feature para este perfil aun no existe.
final class FeatureNotReadyYet extends AuthDestination {
  final ProfileType profileType;
  const FeatureNotReadyYet({required this.profileType});
}

/// Error durante la operacion.
final class AuthDestinationError extends AuthDestination {
  final String message;
  const AuthDestinationError({required this.message});
}
