import 'package:equatable/equatable.dart';

class CultivoEntity extends Equatable {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? familia;
  final String? tipoCultivo;
  final String? imagenUrl;

  const CultivoEntity({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.familia,
    this.tipoCultivo,
    this.imagenUrl,
  });

  @override
  List<Object?> get props => [id, nombre, descripcion, familia, tipoCultivo, imagenUrl];
}
