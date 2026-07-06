// =============================================================================
// Core -- Validadores de Longitud
// =============================================================================
// Capa: Core / Validators
// Evita campos demasiado cortos o largos (nombres, descripciones de
// diagnostico, comentarios).
// =============================================================================

class LengthValidators {
  static String? range(String? value, {required int min, required int max, String field = 'Campo'}) {
    if (value == null) return '$field es obligatorio';
    if (value.length < min) return '$field debe tener al menos $min caracteres';
    if (value.length > max) return '$field no debe exceder $max caracteres';
    return null;
  }
}
