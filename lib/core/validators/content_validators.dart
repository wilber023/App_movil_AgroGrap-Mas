// =============================================================================
// Core -- Validadores de Contenido
// =============================================================================
// Capa: Core / Validators
// Rechaza caracteres no permitidos/peligrosos en campos de texto libre
// (nombres, notas de diagnostico).
// =============================================================================

class ContentValidators {
  // Solo letras (incluye acentos/ñ), espacios y guiones — util para nombres de productor
  static String? safeName(String? value) {
    if (value == null || value.isEmpty) return 'Este campo es obligatorio';
    final regex = RegExp(r"^[a-zA-ZÀ-ÿñÑ\s\-]+$");
    return regex.hasMatch(value) ? null : 'No se permiten caracteres especiales ni números';
  }
}
