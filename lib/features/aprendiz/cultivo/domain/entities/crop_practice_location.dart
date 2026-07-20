/// Lugar donde el aprendiz practicará su cultivo, capturado al registrar
/// un nuevo plan (ver `RegisterCropPlanParams`).
enum CropPracticeLocation { home, greenhouse }

/// Mapeo al contrato del microservicio de Cultivos (`lugar_practica`),
/// confirmado en `README_FRONTEND_APRENDIZ_SIEMBRA.md`: el backend espera
/// los valores en español, no el nombre del enum.
extension CropPracticeLocationApi on CropPracticeLocation {
  String get apiValue => switch (this) {
        CropPracticeLocation.home => 'jardin_casa',
        CropPracticeLocation.greenhouse => 'invernadero',
      };
}
