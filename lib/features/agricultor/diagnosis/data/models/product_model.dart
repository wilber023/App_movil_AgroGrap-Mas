import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.name,
    required super.price,
    super.brand,
    super.description,
    super.imageUrl,
    super.purchaseUrl,
    super.productType,
    super.targetCrops,
    super.targetDiseases,
    super.stockStatus,
    super.rating,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final priceMap = json['price'] as Map<String, dynamic>?;
    final amount = (priceMap?['amount'] as num?)?.toDouble();
    final currency = (priceMap?['currency'] as String?) ?? 'MXN';
    final priceStr = amount != null
        ? '\$${amount.toStringAsFixed(2)} $currency'
        : 'Precio no disponible';

    final stockMap = json['stock'] as Map<String, dynamic>?;

    return ProductModel(
      name: (json['name'] as String?)?.trim() ?? '',
      brand: _s(json['manufacturer']),
      description: _s(json['active_ingredient']),
      imageUrl: _s(json['image_url']),
      price: priceStr,
      purchaseUrl: _s(json['source_url']),
      productType: _s(json['product_type']),
      targetCrops:
          (json['target_crops'] as List<dynamic>? ?? []).cast<String>(),
      targetDiseases:
          (json['target_diseases'] as List<dynamic>? ?? []).cast<String>(),
      stockStatus: _s(stockMap?['status']),
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  static String? _s(dynamic v) {
    if (v == null) return null;
    final s = (v as String).trim();
    return s.isEmpty ? null : s;
  }
}
