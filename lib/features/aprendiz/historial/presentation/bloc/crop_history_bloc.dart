import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/crop_event_entity.dart';
import '../../domain/usecases/get_crop_history_usecase.dart';

// -- States --
sealed class CropHistoryState extends Equatable {
  const CropHistoryState();
  @override
  List<Object?> get props => [];
}

final class CropHistoryLoading extends CropHistoryState {
  const CropHistoryLoading();
}

final class CropHistoryLoaded extends CropHistoryState {
  final List<CropEventEntity> history;
  const CropHistoryLoaded(this.history);
  @override
  List<Object?> get props => [history];
}

final class CropHistoryEmpty extends CropHistoryState {
  const CropHistoryEmpty();
}

final class CropHistoryError extends CropHistoryState {
  final String message;
  const CropHistoryError(this.message);
  @override
  List<Object?> get props => [message];
}

// -- Bloc --
class CropHistoryBloc extends Cubit<CropHistoryState> {
  final GetCropHistoryUseCase getCropHistoryUseCase;

  CropHistoryBloc({required this.getCropHistoryUseCase}) : super(const CropHistoryLoading());

  Future<void> loadHistory() async {
    emit(const CropHistoryLoading());
    final result = await getCropHistoryUseCase(const NoParams());

    result.fold(
      (failure) => emit(CropHistoryError(failure.message)),
      (history) {
        if (history.isEmpty) {
          emit(const CropHistoryEmpty());
        } else {
          emit(CropHistoryLoaded(history));
        }
      },
    );
  }
}
