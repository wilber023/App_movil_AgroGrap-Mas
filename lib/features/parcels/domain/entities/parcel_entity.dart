import 'package:equatable/equatable.dart';

class ParcelEntity extends Equatable {
  final String id;
  final String name;
  final String cropName;
  final double areaSize;
  final String areaUnit;
  final String status; // 'Alerta', 'Seguimiento', 'Saludable', 'Sin diagnostico'
  final DateTime? lastDiagnosisAt;
  final String stageName; // 'Siembra', 'Vegetativo', 'Floracion', 'Cosecha'
  final double stageProgress;
  final int stageIndex;

  const ParcelEntity({
    required this.id,
    required this.name,
    required this.cropName,
    required this.areaSize,
    this.areaUnit = 'ha',
    required this.status,
    this.lastDiagnosisAt,
    required this.stageName,
    required this.stageProgress,
    required this.stageIndex,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        cropName,
        areaSize,
        areaUnit,
        status,
        lastDiagnosisAt,
        stageName,
        stageProgress,
        stageIndex,
      ];
}
