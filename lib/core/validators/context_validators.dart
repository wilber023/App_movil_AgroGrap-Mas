// =============================================================================
// Core -- Validadores Contextuales (UX únicamente)
// =============================================================================
// Capa: Core / Validators
// Validación OPTIMISTA para mejorar la UX (ej. verificar que las
// coordenadas GPS estén dentro del rango geográfico configurado para la
// zona agrícola de cobertura). La validación AUTORITATIVA de si una
// parcela realmente pertenece a una región con cobertura de servicio
// depende del backend (microservicio de zonas/epidemiología) y nunca debe
// confiarse solo en el cliente.
// =============================================================================

/// Rectángulo geográfico simple (evita depender de `google_maps_flutter`
/// solo para esta validación de UX).
class GeoBounds {
  final double southLat;
  final double northLat;
  final double westLng;
  final double eastLng;

  const GeoBounds({
    required this.southLat,
    required this.northLat,
    required this.westLng,
    required this.eastLng,
  });

  /// Zona agrícola de referencia usada por AgroGraph (Chiapas, México).
  static const chiapas = GeoBounds(
    southLat: 14.5,
    northLat: 17.9,
    westLng: -94.1,
    eastLng: -90.2,
  );
}

class ContextValidators {
  static String? withinServiceArea(double lat, double lng, {GeoBounds bounds = GeoBounds.chiapas}) {
    final within = lat >= bounds.southLat &&
        lat <= bounds.northLat &&
        lng >= bounds.westLng &&
        lng <= bounds.eastLng;
    return within ? null : 'La ubicación está fuera del área de cobertura actual';
  }
}
