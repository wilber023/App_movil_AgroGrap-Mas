import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  const ProductEntity({
    required this.name,
    required this.price,
    this.brand,
    this.description,
    this.imageUrl,
    this.purchaseUrl,
    this.productType,
    this.targetCrops = const [],
    this.targetDiseases = const [],
    this.stockStatus,
    this.rating,
  });

  final String name;
  final String? brand;
  final String? description;      // ingrediente activo
  final String? imageUrl;
  final String price;
  final String? purchaseUrl;      // source_url
  final String? productType;      // fungicida | insecticida | herbicida | fertilizante
  final List<String> targetCrops;
  final List<String> targetDiseases;
  final String? stockStatus;      // in_stock | out_of_stock | unknown
  final double? rating;

  @override
  List<Object?> get props => [
        name, brand, description, imageUrl, price, purchaseUrl,
        productType, targetCrops, targetDiseases, stockStatus, rating,
      ];
}
