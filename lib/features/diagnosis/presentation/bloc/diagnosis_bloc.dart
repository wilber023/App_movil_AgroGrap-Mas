import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/diagnosis_entity.dart';

// -- Events --
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

// -- States --
sealed class DiagnosisState extends Equatable {
  const DiagnosisState();
  @override
  List<Object?> get props => [];
}

// Camera states
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
  const DiagnosisProcessing(this.cropName, this.parcelName);
  @override
  List<Object?> get props => [cropName, parcelName];
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

// History states
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

// -- Bloc (ViewModel equivalent) --
class DiagnosisBloc extends Bloc<DiagnosisEvent, DiagnosisState> {
  DiagnosisBloc() : super(const DiagnosisIdle()) {
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

  void _onPhotoCaptured(DiagnosisPhotoCaptured event, Emitter<DiagnosisState> emit) {
    emit(DiagnosisCaptured(event.imagePath));
  }

  Future<void> _onProcessRequested(DiagnosisProcessRequested event, Emitter<DiagnosisState> emit) async {
    final currentState = state;
    if (currentState is! DiagnosisCaptured) return;
    
    emit(DiagnosisProcessing(event.cropName, event.parcelName));
    
    // Simular inferencia local (modelo CNN)
    await Future.delayed(const Duration(seconds: 4));
    
    // Crear el resultado mockeado para cumplir el UI
    final mockResult = DiagnosisEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      diseaseName: 'Tizon tardio',
      scientificName: 'Phytophthora infestans',
      cropName: event.cropName,
      parcelName: event.parcelName,
      severity: 'Critica',
      confidence: 0.91,
      description: 'Enfermedad fungica que afecta hojas y tallos. Avanza rapido en condiciones humedas. Puede destruir hasta el 80% del cultivo si no se trata en los primeros 5 dias.',
      symptoms: event.symptoms,
      recommendationsWhatIs: ['Enfermedad fungica que afecta hojas y tallos. Avanza rapido en condiciones humedas. Puede destruir hasta el 80% del cultivo si no se trata en los primeros 5 dias.'],
      recommendationsWhatToDo: ['Aplica fungicida sistemico (Metalaxil o Mancozeb) a 1.5 ml por litro de agua. Retira las hojas afectadas con guante. Evita riego por aspersion durante el tratamiento.'],
      recommendationsNoAction: 'Perdida estimada de \$3,800 MXN por hectarea en 7-10 dias. La enfermedad puede propagarse a parcelas cercanas.',
      imagePath: currentState.imagePath,
      diagnosedAt: DateTime.now(),
      isPendingSync: true, // Offline first behavior
      statusLabel: 'En tratamiento',
    );
    
    emit(DiagnosisResult(mockResult));
  }

  void _onHistoryRequested(DiagnosisHistoryRequested event, Emitter<DiagnosisState> emit) {
    // Return mock offline data
    final mocks = [
      DiagnosisEntity(
        id: '1',
        diseaseName: 'Tizon tardio',
        scientificName: 'Phytophthora infestans',
        cropName: 'Maiz',
        parcelName: 'Milpa Norte',
        severity: 'Critica',
        confidence: 0.91,
        description: '',
        diagnosedAt: DateTime.now().subtract(const Duration(days: 1)),
        isPendingSync: true,
        treatmentProgress: 0.33,
        treatmentStep: 'Paso 1/3',
        statusLabel: 'En tratamiento',
      ),
      DiagnosisEntity(
        id: '2',
        diseaseName: 'Gusano cogollero',
        scientificName: 'Spodoptera frugiperda',
        cropName: 'Maiz',
        parcelName: 'Milpa Norte',
        severity: 'Moderada',
        confidence: 0.85,
        description: '',
        diagnosedAt: DateTime.now().subtract(const Duration(days: 3)),
        isPendingSync: false,
        treatmentProgress: 0.66,
        treatmentStep: 'Paso 2/3',
        statusLabel: 'Seguimiento',
      ),
    ];
    emit(DiagnosisHistoryLoaded(allItems: mocks, filteredItems: mocks));
  }

  void _onFilterHistory(DiagnosisFilterHistory event, Emitter<DiagnosisState> emit) {
    if (state is DiagnosisHistoryLoaded) {
      final current = state as DiagnosisHistoryLoaded;
      List<DiagnosisEntity> filtered = current.allItems;
      
      if (event.filter != 'Todos') {
        if (event.filter == 'Con alerta') {
          filtered = current.allItems.where((e) => e.severity == 'Critica' || e.severity == 'Moderada').toList();
        } else if (event.filter == 'En tratamiento') {
          filtered = current.allItems.where((e) => e.statusLabel == 'En tratamiento').toList();
        } else if (event.filter == 'Saludable') {
          filtered = current.allItems.where((e) => e.severity == 'Saludable').toList();
        }
      }
      
      emit(DiagnosisHistoryLoaded(
        allItems: current.allItems,
        filteredItems: filtered,
        activeFilter: event.filter,
      ));
    }
  }

  void _onReset(DiagnosisReset event, Emitter<DiagnosisState> emit) {
    emit(const DiagnosisIdle());
  }
}
