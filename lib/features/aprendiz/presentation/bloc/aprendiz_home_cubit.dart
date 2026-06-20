import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/crop_activity_entity.dart';
import '../../domain/entities/crop_plan_entity.dart';
import '../../domain/entities/crop_health_entity.dart';
import '../../domain/usecases/get_due_inspection_activity_usecase.dart';
import '../../domain/usecases/postpone_activity_usecase.dart';
import '../../domain/usecases/get_saved_crop_plan_usecase.dart';
import '../../domain/usecases/get_crop_health_indicator_usecase.dart';
import '../../../../core/network/network_info.dart';

// -- States --
class AprendizHomeState extends Equatable {
  final bool isLoading;
  final CropActivityEntity? dueInspection;
  final CropPlanEntity? cropPlan;
  final CropHealthEntity? cropHealth;
  final bool modalAlreadyShown;
  final String? errorMessage;
  final bool isOffline;

  const AprendizHomeState({
    this.isLoading = false,
    this.dueInspection,
    this.cropPlan,
    this.cropHealth,
    this.modalAlreadyShown = false,
    this.errorMessage,
    this.isOffline = false,
  });

  AprendizHomeState copyWith({
    bool? isLoading,
    CropActivityEntity? dueInspection,
    CropPlanEntity? cropPlan,
    CropHealthEntity? cropHealth,
    bool? modalAlreadyShown,
    String? errorMessage,
    bool? isOffline,
  }) {
    return AprendizHomeState(
      isLoading: isLoading ?? this.isLoading,
      dueInspection: dueInspection ?? this.dueInspection,
      cropPlan: cropPlan ?? this.cropPlan,
      cropHealth: cropHealth ?? this.cropHealth,
      modalAlreadyShown: modalAlreadyShown ?? this.modalAlreadyShown,
      errorMessage: errorMessage ?? this.errorMessage,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  List<Object?> get props => [isLoading, dueInspection, cropPlan, cropHealth, modalAlreadyShown, errorMessage, isOffline];
}

// -- Cubit --
class AprendizHomeCubit extends Cubit<AprendizHomeState> {
  final GetDueInspectionActivityUseCase getDueInspectionActivityUseCase;
  final PostponeActivityUseCase postponeActivityUseCase;
  final GetSavedCropPlanUseCase getSavedCropPlanUseCase;
  final GetCropHealthIndicatorUseCase getCropHealthIndicatorUseCase;
  final NetworkInfo networkInfo;

  AprendizHomeCubit({
    required this.getDueInspectionActivityUseCase,
    required this.postponeActivityUseCase,
    required this.getSavedCropPlanUseCase,
    required this.getCropHealthIndicatorUseCase,
    required this.networkInfo,
  }) : super(const AprendizHomeState());

  Future<void> loadHomeData() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    
    final isOffline = !(await networkInfo.isConnected);

    final inspectionResult = await getDueInspectionActivityUseCase(const NoParams());
    final planResult = await getSavedCropPlanUseCase(const NoParams());
    final healthResult = await getCropHealthIndicatorUseCase(const NoParams());

    CropActivityEntity? dueActivity;
    inspectionResult.fold((_) {}, (activity) => dueActivity = activity);

    CropPlanEntity? plan;
    planResult.fold((_) {}, (p) => plan = p);

    CropHealthEntity? health;
    healthResult.fold((_) {}, (h) => health = h);

    if (plan == null) {
      emit(state.copyWith(isLoading: false, errorMessage: 'No se pudo cargar el plan de cultivo.'));
      return;
    }

    emit(AprendizHomeState(
      isLoading: false,
      dueInspection: dueActivity,
      cropPlan: plan,
      cropHealth: health,
      modalAlreadyShown: state.modalAlreadyShown,
      isOffline: isOffline,
    ));
  }

  void markModalAsShown() {
    emit(state.copyWith(modalAlreadyShown: true));
  }

  Future<void> postponeInspection(String activityId) async {
    emit(state.copyWith(isLoading: true));
    final result = await postponeActivityUseCase(PostponeActivityParams(
      activityId: activityId, 
      reason: 'Pospuesto desde inicio',
    ));
    
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (_) {
        loadHomeData();
      },
    );
  }
}
