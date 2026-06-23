import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../data/services/cnn_engine.dart';
import '../../domain/entities/diagnosis_entity.dart';

// =============================================================================
// AgroGraph-MAS -- DiagnosisBloc
// Inferencia CNN real vía TFLite (EfficientNet-B4).
// El modelo detecta cultivo y enfermedad directamente del rawLabel.
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
  const DiagnosisProcessRequested();
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
  final String imagePath;
  const DiagnosisProcessing(this.imagePath);
  @override
  List<Object?> get props => [imagePath];
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

    emit(DiagnosisProcessing(current.imagePath));

    try {
      final cnn = await CnnEngine.analyze(current.imagePath);

      final entity = DiagnosisEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        diseaseName: cnn.diseaseName,
        cropName: cnn.cropName,
        confidence: cnn.confidence,
        imagePath: current.imagePath,
        diagnosedAt: DateTime.now(),
        isPendingSync: true,
        statusLabel: _statusForDisease(cnn.diseaseName),
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
            .where((e) => e.statusLabel != 'Saludable')
            .toList();
      case 'En tratamiento':
        filtered = current.allItems
            .where((e) => e.statusLabel == 'En tratamiento')
            .toList();
      case 'Saludable':
        filtered = current.allItems
            .where((e) => e.statusLabel == 'Saludable')
            .toList();
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

  /// Deriva el statusLabel directamente del nombre de enfermedad detectado.
  String _statusForDisease(String diseaseName) {
    if (diseaseName.toLowerCase().contains('saludable')) return 'Saludable';
    return 'Seguimiento';
  }

  Future<void> _persistDiagnosis(DiagnosisEntity entity) async {
    try {
      final encoded = jsonEncode({
        'id': entity.id,
        'diseaseName': entity.diseaseName,
        'cropName': entity.cropName,
        'confidence': entity.confidence,
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
      cropName: m['cropName'] as String? ?? '',
      confidence: (m['confidence'] as num?)?.toDouble() ?? 0.0,
      imagePath: m['imagePath'] as String?,
      diagnosedAt:
          DateTime.tryParse(m['diagnosedAt'] as String? ?? '') ?? DateTime.now(),
      isPendingSync: m['isPendingSync'] as bool? ?? false,
      statusLabel: m['statusLabel'] as String? ?? 'Seguimiento',
      // topK vacío en historial persistido (no se guarda)
    );
  }
}
