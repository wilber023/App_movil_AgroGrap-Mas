import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/error/failures.dart';
import '../entities/cultivo_entity.dart';
import '../entities/parcel_entity.dart';

abstract class ParcelRepository {
  Future<Either<Failure, List<ParcelEntity>>> getParcels();
  Future<Either<Failure, ParcelEntity>> getParcelDetail(String seleccionId);
  Future<Either<Failure, ParcelEntity>> addParcel(AddParcelParams params);
  Future<Either<Failure, void>> deleteParcel(String seleccionId);
  Future<Either<Failure, List<CultivoEntity>>> getCultivoCatalog();

  /// Región/Comunidad de una parcela, leída de la caché local (sin red).
  /// `null` si no hay nada cacheado para ese `seleccionId`.
  Future<String?> getRegionLocal(String seleccionId);

  /// Todas las parcelas del usuario cacheadas localmente (sin red).
  Future<List<ParcelEntity>> getParcelsLocal();
}

class AddParcelParams extends Equatable {
  final String cultivoId;
  final String cultivoNombre;
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
    required this.cultivoNombre,
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
