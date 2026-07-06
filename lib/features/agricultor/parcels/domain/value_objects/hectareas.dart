// =============================================================================
// Feature: Parcels -- Value Object: Hectareas
// =============================================================================
// Capa: Domain
// Fuerza el tipo numérico en su propio constructor: un TextField siempre
// entrega String, así que el parseo/validación de tipo debe ocurrir antes
// de construir el DTO que se envía al backend (AddParcelParams.areaHa).
// =============================================================================

class Hectareas {
  final double value;

  Hectareas(String raw) : value = _parse(raw);

  static double _parse(String raw) {
    final parsed = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (parsed == null) throw FormatException('La superficie debe ser un valor numérico');
    if (parsed <= 0) throw FormatException('La superficie debe ser mayor que 0');
    if (parsed > 100000) throw FormatException('La superficie ingresada es demasiado grande');
    return parsed;
  }

  /// Variante segura para UI: retorna el mensaje de error o `null` si es válida.
  static String? validate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'La superficie es obligatoria';
    try {
      Hectareas(raw);
      return null;
    } on FormatException catch (e) {
      return e.message;
    }
  }
}
