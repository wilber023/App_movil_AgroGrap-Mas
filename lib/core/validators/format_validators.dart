// =============================================================================
// Core -- Validadores de Formato
// =============================================================================
// Capa: Core / Validators
// Funciones puras reutilizables por cualquier FormFieldValidator de
// presentation/. Verifican que el dato cumpla un formato esperado
// (correo, telefono, fecha) antes de enviarlo al backend.
// =============================================================================

class FormatValidators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'El correo es obligatorio';
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(value) ? null : 'Formato de correo inválido';
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'El teléfono es obligatorio';
    final regex = RegExp(r'^\+?[0-9]{10,13}$');
    return regex.hasMatch(value) ? null : 'Teléfono inválido';
  }

  static String? date(String? value, {String pattern = r'^\d{4}-\d{2}-\d{2}$'}) {
    if (value == null || value.isEmpty) return 'La fecha es obligatoria';
    return RegExp(pattern).hasMatch(value) ? null : 'Formato de fecha inválido (YYYY-MM-DD)';
  }
}
