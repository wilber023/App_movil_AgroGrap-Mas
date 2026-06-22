import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../data/services/cnn_engine.dart';
import '../../domain/entities/diagnosis_entity.dart';

// =============================================================================
// AgroGraph-MAS -- DiagnosisBloc
// Inferencia CNN real vía TFLite (EfficientNet-B4, 50 clases, 96.69% accuracy).
// Sin mocks, sin delays artificiales, sin datos hardcodeados.
// =============================================================================

// -- Events ------------------------------------------------------------------

sealed class DiagnosisEvent extends Equatable {
  const DiagnosisEvent();
  @override
  List<Object?> get props => [];
}

final class DiagnosisCameraIdle extends DiagnosisEvent {
  const DiagnosisCameraIdle();
}

final class DiagnosisPhotoCaptured extends DiagnosisEvent {
  final String imagePath;
  const DiagnosisPhotoCaptured(this.imagePath);
  @override
  List<Object?> get props => [imagePath];
}

final class DiagnosisProcessRequested extends DiagnosisEvent {
  final String cropName;
  final String? parcelName;
  final String description;
  final List<String> symptoms;

  const DiagnosisProcessRequested({
    required this.cropName,
    this.parcelName,
    required this.description,
    required this.symptoms,
  });

  @override
  List<Object?> get props => [cropName, parcelName, description, symptoms];
}

final class DiagnosisHistoryRequested extends DiagnosisEvent {
  const DiagnosisHistoryRequested();
}

final class DiagnosisFilterHistory extends DiagnosisEvent {
  final String filter;
  const DiagnosisFilterHistory(this.filter);
  @override
  List<Object?> get props => [filter];
}

final class DiagnosisReset extends DiagnosisEvent {
  const DiagnosisReset();
}

// -- States ------------------------------------------------------------------

sealed class DiagnosisState extends Equatable {
  const DiagnosisState();
  @override
  List<Object?> get props => [];
}

final class DiagnosisIdle extends DiagnosisState {
  const DiagnosisIdle();
}

final class DiagnosisCaptured extends DiagnosisState {
  final String imagePath;
  const DiagnosisCaptured(this.imagePath);
  @override
  List<Object?> get props => [imagePath];
}

final class DiagnosisProcessing extends DiagnosisState {
  final String cropName;
  final String? parcelName;
  final String imagePath;
  const DiagnosisProcessing(this.cropName, this.parcelName, this.imagePath);
  @override
  List<Object?> get props => [cropName, parcelName, imagePath];
}

final class DiagnosisResult extends DiagnosisState {
  final DiagnosisEntity diagnosis;
  const DiagnosisResult(this.diagnosis);
  @override
  List<Object?> get props => [diagnosis];
}

final class DiagnosisError extends DiagnosisState {
  final String message;
  const DiagnosisError(this.message);
  @override
  List<Object?> get props => [message];
}

final class DiagnosisHistoryLoaded extends DiagnosisState {
  final List<DiagnosisEntity> allItems;
  final List<DiagnosisEntity> filteredItems;
  final String activeFilter;

  const DiagnosisHistoryLoaded({
    required this.allItems,
    required this.filteredItems,
    this.activeFilter = 'Todos',
  });

  @override
  List<Object?> get props => [allItems, filteredItems, activeFilter];
}

// -- Bloc --------------------------------------------------------------------

class DiagnosisBloc extends Bloc<DiagnosisEvent, DiagnosisState> {
  final Box<String> _historyBox;

  DiagnosisBloc({required Box<String> historyBox})
      : _historyBox = historyBox,
        super(const DiagnosisIdle()) {
    on<DiagnosisCameraIdle>(_onCameraIdle);
    on<DiagnosisPhotoCaptured>(_onPhotoCaptured);
    on<DiagnosisProcessRequested>(_onProcessRequested);
    on<DiagnosisHistoryRequested>(_onHistoryRequested);
    on<DiagnosisFilterHistory>(_onFilterHistory);
    on<DiagnosisReset>(_onReset);
  }

  void _onCameraIdle(DiagnosisCameraIdle event, Emitter<DiagnosisState> emit) {
    emit(const DiagnosisIdle());
  }

  void _onPhotoCaptured(
      DiagnosisPhotoCaptured event, Emitter<DiagnosisState> emit) {
    emit(DiagnosisCaptured(event.imagePath));
  }

  Future<void> _onProcessRequested(
      DiagnosisProcessRequested event, Emitter<DiagnosisState> emit) async {
    final current = state;
    if (current is! DiagnosisCaptured) return;

    emit(DiagnosisProcessing(event.cropName, event.parcelName, current.imagePath));

    try {
      // Inferencia CNN real: preprocessing (isolate) + TFLite (hilo principal)
      final cnn = await CnnEngine.analyze(current.imagePath);

      final entity = DiagnosisEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        diseaseName: cnn.diseaseName,
        scientificName: cnn.scientificName,
        // El CNN detecta el cultivo directamente; el campo cropName del evento
        // se usa solo si el usuario lo especificó explícitamente.
        cropName: event.cropName.isNotEmpty ? event.cropName : cnn.cropName,
        parcelName: event.parcelName,
        severity: cnn.severity,
        confidence: cnn.confidence,
        description: event.description,
        symptoms: event.symptoms.isNotEmpty ? event.symptoms : const [],
        recommendationsWhatIs: cnn.whatIs,
        recommendationsWhatToDo: cnn.whatToDo,
        recommendationsNoAction: cnn.ifNoAction,
        imagePath: current.imagePath,
        diagnosedAt: DateTime.now(),
        isPendingSync: true,
        statusLabel: _statusForSeverity(cnn.severity),
        topK: cnn.topK,
      );

      await _persistDiagnosis(entity);
      emit(DiagnosisResult(entity));
    } on StateError catch (e) {
      debugPrint('[DiagnosisBloc] Modelo no disponible: $e');
      emit(const DiagnosisError(
        'Modelo CNN no disponible.\nEjecuta convert_to_tflite.py para generar best.tflite.',
      ));
    } catch (e) {
      debugPrint('[DiagnosisBloc] Error en inferencia CNN: $e');
      emit(const DiagnosisError(
        'No se pudo analizar la imagen. Asegúrate de tener buena iluminación e intenta de nuevo.',
      ));
    }
  }

  void _onHistoryRequested(
      DiagnosisHistoryRequested event, Emitter<DiagnosisState> emit) {
    final items = _loadHistory();
    emit(DiagnosisHistoryLoaded(allItems: items, filteredItems: items));
  }

  void _onFilterHistory(
      DiagnosisFilterHistory event, Emitter<DiagnosisState> emit) {
    if (state is! DiagnosisHistoryLoaded) return;
    final current = state as DiagnosisHistoryLoaded;

    List<DiagnosisEntity> filtered = current.allItems;
    switch (event.filter) {
      case 'Con alerta':
        filtered = current.allItems
            .where((e) => e.severity == 'Critica' || e.severity == 'Moderada')
            .toList();
      case 'En tratamiento':
        filtered = current.allItems
            .where((e) => e.statusLabel == 'En tratamiento')
            .toList();
      case 'Saludable':
        filtered =
            current.allItems.where((e) => e.severity == 'Saludable').toList();
    }

    emit(DiagnosisHistoryLoaded(
      allItems: current.allItems,
      filteredItems: filtered,
      activeFilter: event.filter,
    ));
  }

  void _onReset(DiagnosisReset event, Emitter<DiagnosisState> emit) {
    emit(const DiagnosisIdle());
  }

  // -- Helpers ---------------------------------------------------------------

  String _statusForSeverity(String severity) {
    switch (severity) {
      case 'Critica':
      case 'Moderada':
        return 'En tratamiento';
      case 'Leve':
        return 'Seguimiento';
      case 'Saludable':
        return 'Saludable';
      default:
        return 'Seguimiento';
    }
  }

  Future<void> _persistDiagnosis(DiagnosisEntity entity) async {
    try {
      final encoded = jsonEncode({
        'id': entity.id,
        'diseaseName': entity.diseaseName,
        'scientificName': entity.scientificName,
        'cropName': entity.cropName,
        'parcelName': entity.parcelName,
        'severity': entity.severity,
        'confidence': entity.confidence,
        'description': entity.description,
        'symptoms': entity.symptoms,
        'recommendationsWhatIs': entity.recommendationsWhatIs,
        'recommendationsWhatToDo': entity.recommendationsWhatToDo,
        'recommendationsNoAction': entity.recommendationsNoAction,
        'imagePath': entity.imagePath,
        'diagnosedAt': entity.diagnosedAt.toIso8601String(),
        'isPendingSync': entity.isPendingSync,
        'statusLabel': entity.statusLabel,
        // topK no se persiste (solo vive en sesión)
      });
      await _historyBox.add(encoded);
    } catch (e) {
      debugPrint('[DiagnosisBloc] Error al persistir en Hive: $e');
    }
  }

  List<DiagnosisEntity> _loadHistory() {
    final items = <DiagnosisEntity>[];
    for (final raw in _historyBox.values) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        items.add(_mapToEntity(m));
      } catch (e) {
        debugPrint('[DiagnosisBloc] Error al deserializar historial: $e');
      }
    }
    return items.reversed.toList();
  }

  DiagnosisEntity _mapToEntity(Map<String, dynamic> m) {
    return DiagnosisEntity(
      id: m['id'] as String? ?? '',
      diseaseName: m['diseaseName'] as String? ?? '',
      scientificName: m['scientificName'] as String? ?? '',
      cropName: m['cropName'] as String? ?? '',
      parcelName: m['parcelName'] as String?,
      severity: m['severity'] as String? ?? 'Leve',
      confidence: (m['confidence'] as num?)?.toDouble() ?? 0.0,
      description: m['description'] as String? ?? '',
      symptoms: (m['symptoms'] as List?)?.cast<String>() ?? [],
      recommendationsWhatIs:
          (m['recommendationsWhatIs'] as List?)?.cast<String>() ?? [],
      recommendationsWhatToDo:
          (m['recommendationsWhatToDo'] as List?)?.cast<String>() ?? [],
      recommendationsNoAction: m['recommendationsNoAction'] as String? ?? '',
      imagePath: m['imagePath'] as String?,
      diagnosedAt:
          DateTime.tryParse(m['diagnosedAt'] as String? ?? '') ?? DateTime.now(),
      isPendingSync: m['isPendingSync'] as bool? ?? false,
      statusLabel: m['statusLabel'] as String? ?? 'Seguimiento',
      // topK vacío en historial persistido (no se guarda)
    );
  }
}
