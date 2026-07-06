// =============================================================================
// Core -- Validador Regex Genérico
// =============================================================================
// Capa: Core / Validators
// Motor genérico reutilizable para cualquier patrón, usado por los
// validadores especializados de este mismo directorio.
// =============================================================================

class RegexValidator {
  static String? matches(String? value, RegExp pattern, {String errorMessage = 'Formato inválido'}) {
    if (value == null || value.isEmpty) return 'Este campo es obligatorio';
    return pattern.hasMatch(value) ? null : errorMessage;
  }
}
