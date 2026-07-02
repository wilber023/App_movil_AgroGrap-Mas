import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product_entity.dart';

/// Contrato del repositorio de productos recomendados.
/// La implementacion vive en la capa data.
abstract interface class ProductRepository {
  /// Obtiene productos recomendados segun la [disease] detectada y
  /// opcionalmente el [crop] para mejorar la relevancia de resultados.
  ///
  /// Retorna un par ([productType], [products]) o un [Failure].
  Future<Either<Failure, ({String? productType, List<ProductEntity> products})>>
      getRecommendedProducts({
    required String disease,
    String? crop,
  });
}
