import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../diagnosis/domain/entities/diagnosis_entity.dart';
import '../../domain/usecases/analyze_crop_aprendiz_usecase.dart';

abstract class DiagnosisCameraAprendizState extends Equatable {
  const DiagnosisCameraAprendizState();
  
  @override
  List<Object?> get props => [];
}

class DiagnosisCameraAprendizInitial extends DiagnosisCameraAprendizState {}

class DiagnosisCameraAprendizLoading extends DiagnosisCameraAprendizState {}

class DiagnosisCameraAprendizSuccess extends DiagnosisCameraAprendizState {
  final DiagnosisEntity diagnosis;

  const DiagnosisCameraAprendizSuccess(this.diagnosis);

  @override
  List<Object?> get props => [diagnosis];
}

class DiagnosisCameraAprendizError extends DiagnosisCameraAprendizState {
  final String message;

  const DiagnosisCameraAprendizError(this.message);

  @override
  List<Object?> get props => [message];
}

class DiagnosisCameraAprendizCubit extends Cubit<DiagnosisCameraAprendizState> {
  final AnalyzeCropAprendizUseCase analyzeCropUseCase;

  DiagnosisCameraAprendizCubit({required this.analyzeCropUseCase}) : super(DiagnosisCameraAprendizInitial());

  Future<void> analyzeCrop(String imagePath, String? description) async {
    emit(DiagnosisCameraAprendizLoading());
    final result = await analyzeCropUseCase(AnalyzeCropAprendizParams(imagePath: imagePath, description: description));
    result.fold(
      (failure) => emit(DiagnosisCameraAprendizError(failure.message)),
      (diagnosis) => emit(DiagnosisCameraAprendizSuccess(diagnosis)),
    );
  }
}
