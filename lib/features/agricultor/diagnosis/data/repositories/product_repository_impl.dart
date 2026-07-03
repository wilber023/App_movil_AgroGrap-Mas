import 'package:dartz/dartz.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/network_info.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl({
    required ProductRemoteDataSource dataSource,
    required NetworkInfo networkInfo,
  })  : _dataSource = dataSource,
        _networkInfo = networkInfo;

  final ProductRemoteDataSource _dataSource;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, ({String? productType, List<ProductEntity> products})>>
      getRecommendedProducts({
    required String disease,
    String? crop,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await _dataSource.getRecommendedProducts(
        disease: disease,
        crop: crop,
      );
      return Right((productType: result.productType, products: result.products));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
