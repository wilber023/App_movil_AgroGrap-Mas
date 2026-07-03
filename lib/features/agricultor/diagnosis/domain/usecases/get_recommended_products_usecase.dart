import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

/// Parametros para la consulta de productos recomendados.
class GetProductsParams {
  const GetProductsParams({required this.disease, this.crop});

  /// Enfermedad detectada por el LLM/CNN.
  final String disease;

  /// Cultivo afectado. Mejora la relevancia de resultados. Puede ser null.
  final String? crop;
}

/// Caso de uso: obtiene la lista de productos recomendados para una enfermedad.
class GetRecommendedProductsUseCase
    implements
        UseCase<({String? productType, List<ProductEntity> products}),
            GetProductsParams> {
  const GetRecommendedProductsUseCase(this._repository);

  final ProductRepository _repository;

  @override
  Future<
      Either<Failure,
          ({String? productType, List<ProductEntity> products})>> call(
    GetProductsParams params,
  ) =>
      _repository.getRecommendedProducts(
        disease: params.disease,
        crop: params.crop,
      );
}
