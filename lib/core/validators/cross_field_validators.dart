// =============================================================================
// Core -- Validadores Cruzados
// =============================================================================
// Capa: Core / Validators (consumido desde presentation/ o desde el
// Bloc/Controller antes de invocar el UseCase, ya que necesita el valor
// de dos campos a la vez).
// =============================================================================

class CrossFieldValidators {
  static String? dateOrder(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'Ambas fechas son obligatorias';
    if (start.isAfter(end)) return 'La fecha de inicio no puede ser posterior a la de fin';
    return null;
  }

  static String? passwordsMatch(String password, String confirmation) {
    return password == confirmation ? null : 'Las contraseñas no coinciden';
  }
}
