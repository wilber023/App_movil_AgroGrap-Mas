import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

enum CropEventType {
  siembra,
  inspeccionSinPatologia,
  fertilizacion,
  deteccionEnfermedad,
  tratamientoAplicado,
  mejoraObservada,
  actividadPospuesta,
}

extension CropEventTypeExtension on CropEventType {
  IconData get icon {
    switch (this) {
      case CropEventType.siembra:
        return Icons.eco_rounded; // planta
      case CropEventType.inspeccionSinPatologia:
        return Icons.visibility_rounded; // ojo
      case CropEventType.fertilizacion:
        return Icons.water_drop_rounded; // gota
      case CropEventType.deteccionEnfermedad:
        return Icons.warning_rounded; // alerta
      case CropEventType.tratamientoAplicado:
        return Icons.medication_rounded; // cápsula
      case CropEventType.mejoraObservada:
        return Icons.trending_up_rounded; // tendencia-arriba
      case CropEventType.actividadPospuesta:
        return Icons.pause_circle_filled_rounded; // pausa
    }
  }

  Color get backgroundColor {
    switch (this) {
      case CropEventType.siembra:
      case CropEventType.inspeccionSinPatologia:
      case CropEventType.mejoraObservada:
        return AppColors.primaryContainer; // verde claro
      case CropEventType.fertilizacion:
        return Colors.lightBlue.shade100; // azul claro
      case CropEventType.deteccionEnfermedad:
        return AppColors.errorContainer; // rojo claro
      case CropEventType.tratamientoAplicado:
        return Colors.orange.shade100; // ámbar claro
      case CropEventType.actividadPospuesta:
        return AppColors.surfaceVariant; // gris claro
    }
  }

  Color get iconColor {
    switch (this) {
      case CropEventType.siembra:
      case CropEventType.inspeccionSinPatologia:
      case CropEventType.mejoraObservada:
        return AppColors.forestGreen; // verde oscuro
      case CropEventType.fertilizacion:
        return Colors.blue; // azul
      case CropEventType.deteccionEnfermedad:
        return AppColors.error; // rojo
      case CropEventType.tratamientoAplicado:
        return Colors.orange.shade800; // ámbar
      case CropEventType.actividadPospuesta:
        return AppColors.onSurfaceVariant; // gris
    }
  }
}

class CropEventEntity extends Equatable {
  final String id;
  final CropEventType type;
  final String title;
  final String description;
  final DateTime date;
  final String? relatedActivityId;

  const CropEventEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.date,
    this.relatedActivityId,
  });

  @override
  List<Object?> get props => [id, type, title, description, date, relatedActivityId];
}
