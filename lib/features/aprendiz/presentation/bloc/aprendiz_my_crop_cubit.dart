import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/crop_plan_entity.dart';
import '../../domain/usecases/get_saved_crop_plan_usecase.dart';
import '../../../../core/network/network_info.dart';

abstract class AprendizMyCropState extends Equatable {
  const AprendizMyCropState();

  @override
  List<Object?> get props => [];
}

class AprendizMyCropLoading extends AprendizMyCropState {}

class AprendizMyCropLoaded extends AprendizMyCropState {
  final CropPlanEntity plan;
  final bool isOffline;

  const AprendizMyCropLoaded(this.plan, {this.isOffline = false});

  @override
  List<Object?> get props => [plan, isOffline];
}

class AprendizMyCropError extends AprendizMyCropState {
  final String message;

  const AprendizMyCropError(this.message);

  @override
  List<Object?> get props => [message];
}

class AprendizMyCropCubit extends Cubit<AprendizMyCropState> {
  final GetSavedCropPlanUseCase getSavedCropPlanUseCase;
  final NetworkInfo networkInfo;

  AprendizMyCropCubit({
    required this.getSavedCropPlanUseCase,
    required this.networkInfo,
  }) : super(AprendizMyCropLoading());

  Future<void> loadPlan() async {
    emit(AprendizMyCropLoading());

    final isOffline = !(await networkInfo.isConnected);

    final result = await getSavedCropPlanUseCase(const NoParams());
    result.fold(
      (failure) => emit(AprendizMyCropError(failure.message)),
      (plan) => emit(AprendizMyCropLoaded(plan, isOffline: isOffline)),
    );
  }
}
