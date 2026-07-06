// =============================================================================
// Core -- Validadores de Rango
// =============================================================================
// Capa: Core / Validators
// Para datos numericos: area de parcela en hectareas, edad del productor,
// humedad/temperatura reportada manualmente, etc.
// =============================================================================

class RangeValidators {
  static String? numericRange(num? value, {required num min, required num max, String field = 'Valor'}) {
    if (value == null) return '$field es obligatorio';
    if (value < min || value > max) return '$field debe estar entre $min y $max';
    return null;
  }
}
