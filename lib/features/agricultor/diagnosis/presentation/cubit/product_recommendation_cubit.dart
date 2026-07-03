import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_recommended_products_usecase.dart';

// =============================================================================
// STATES
// =============================================================================

sealed class ProductRecommendationState extends Equatable {
  const ProductRecommendationState();
  @override
  List<Object?> get props => [];
}

final class ProductRecommendationIdle extends ProductRecommendationState {
  const ProductRecommendationIdle();
}

final class ProductRecommendationLoading extends ProductRecommendationState {
  const ProductRecommendationLoading();
}

final class ProductRecommendationLoaded extends ProductRecommendationState {
  const ProductRecommendationLoaded({
    required this.products,
    this.productType,
  });

  final List<ProductEntity> products;

  /// Tipo inferido por el servicio: "fungicida", "insecticida", etc.
  final String? productType;

  @override
  List<Object?> get props => [products, productType];
}

final class ProductRecommendationError extends ProductRecommendationState {
  const ProductRecommendationError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// =============================================================================
// CUBIT
// =============================================================================

class ProductRecommendationCubit
    extends Cubit<ProductRecommendationState> {
  ProductRecommendationCubit(this._getProducts)
      : super(const ProductRecommendationIdle());

  final GetRecommendedProductsUseCase _getProducts;

  Future<void> getRecommendations({
    required String disease,
    String? crop,
  }) async {
    if (isClosed) return;
    emit(const ProductRecommendationLoading());

    final result = await _getProducts(
      GetProductsParams(disease: disease, crop: crop),
    );

    if (isClosed) return;

    result.fold(
      (failure) =>
          emit(ProductRecommendationError(message: failure.message)),
      (data) => emit(ProductRecommendationLoaded(
        products: data.products,
        productType: data.productType,
      )),
    );
  }
}
