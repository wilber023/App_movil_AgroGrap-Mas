import '../../domain/entities/cultivo_entity.dart';

class CultivoModel extends CultivoEntity {
  const CultivoModel({
    required super.id,
    required super.nombre,
    super.descripcion,
    super.familia,
    super.tipoCultivo,
    super.imagenUrl,
  });

  factory CultivoModel.fromJson(Map<String, dynamic> json) {
    return CultivoModel(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      familia: json['familia']?.toString(),
      tipoCultivo: (json['tipo_cultivo'] ?? json['tipoCultivo'])?.toString(),
      imagenUrl: (json['imagen_url'] ?? json['imagenUrl'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'familia': familia,
        'tipo_cultivo': tipoCultivo,
        'imagen_url': imagenUrl,
      };
}
