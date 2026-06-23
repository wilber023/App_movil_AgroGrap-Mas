import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../entities/cultivo_entity.dart';
import '../entities/parcel_entity.dart';

abstract class ParcelRepository {
  Future<Either<Failure, List<ParcelEntity>>> getParcels();
  Future<Either<Failure, ParcelEntity>> getParcelDetail(int seleccionId);
  Future<Either<Failure, ParcelEntity>> addParcel(AddParcelParams params);
  Future<Either<Failure, void>> deleteParcel(int seleccionId);
  Future<Either<Failure, List<CultivoEntity>>> getCultivoCatalog();
}

class AddParcelParams extends Equatable {
  final int cultivoId;
  final String nombreParcela;
  final double areaHa;
  final String unidadArea;
  final String region;
  final DateTime fechaSiembra;
  final String? terrenoTipo;
  final List<String>? sueloCondiciones;
  final List<String>? malezaTipos;

  const AddParcelParams({
    required this.cultivoId,
    required this.nombreParcela,
    required this.areaHa,
    required this.unidadArea,
    required this.region,
    required this.fechaSiembra,
    this.terrenoTipo,
    this.sueloCondiciones,
    this.malezaTipos,
  });

  @override
  List<Object?> get props => [
        cultivoId,
        nombreParcela,
        areaHa,
        unidadArea,
        region,
        fechaSiembra,
        terrenoTipo,
        sueloCondiciones,
        malezaTipos,
      ];
}
