import 'package:equatable/equatable.dart';

class ParcelEntity extends Equatable {
  final String id;
  final int seleccionId;
  final int cultivoId;
  final String name;
  final String cropName;
  final double areaSize;
  final String areaUnit;
  final String region;
  final DateTime? fechaSiembra;
  final String status; // 'Alerta', 'Seguimiento', 'Saludable', 'Sin diagnostico'
  final DateTime? lastDiagnosisAt;
  final String stageName; // 'Siembra', 'Vegetativo', 'Floracion', 'Cosecha'
  final double stageProgress;
  final int stageIndex;

  const ParcelEntity({
    required this.id,
    required this.seleccionId,
    required this.cultivoId,
    required this.name,
    required this.cropName,
    required this.areaSize,
    this.areaUnit = 'ha',
    this.region = '',
    this.fechaSiembra,
    required this.status,
    this.lastDiagnosisAt,
    required this.stageName,
    required this.stageProgress,
    required this.stageIndex,
  });

  @override
  List<Object?> get props => [
        id,
        seleccionId,
        cultivoId,
        name,
        cropName,
        areaSize,
        areaUnit,
        region,
        fechaSiembra,
        status,
        lastDiagnosisAt,
        stageName,
        stageProgress,
        stageIndex,
      ];
}
