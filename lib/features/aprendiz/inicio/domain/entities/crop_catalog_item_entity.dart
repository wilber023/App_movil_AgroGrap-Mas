import 'package:equatable/equatable.dart';

/// Item del catalogo de cultivos que el Aprendiz puede sembrar (mismo
/// catalogo real usado por Registrar Cultivo — ver
/// `aprendiz_crop_register_page.dart`). `isActive` marca el que coincide con
/// el `CropPlanEntity` realmente registrado por el usuario; el resto solo
/// indica que esta disponible para registrar, no que el usuario lo tenga.
class CropCatalogItemEntity extends Equatable {
  final String emoji;
  final String name;
  final bool isActive;

  const CropCatalogItemEntity({
    required this.emoji,
    required this.name,
    required this.isActive,
  });

  @override
  List<Object?> get props => [emoji, name, isActive];
}
