import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/push_notification_entry_entity.dart';
import '../../domain/usecases/get_notification_history_usecase.dart';

sealed class NotificationHistoryState extends Equatable {
  const NotificationHistoryState();
  @override
  List<Object?> get props => [];
}

final class NotificationHistoryLoading extends NotificationHistoryState {
  const NotificationHistoryLoading();
}

final class NotificationHistoryLoaded extends NotificationHistoryState {
  final List<PushNotificationEntryEntity> items;
  const NotificationHistoryLoaded({required this.items});
  @override
  List<Object?> get props => [items];
}

final class NotificationHistoryError extends NotificationHistoryState {
  final String message;
  const NotificationHistoryError({required this.message});
  @override
  List<Object?> get props => [message];
}

class NotificationHistoryCubit extends Cubit<NotificationHistoryState> {
  final GetNotificationHistoryUseCase _getHistoryUseCase;

  NotificationHistoryCubit({required GetNotificationHistoryUseCase getHistoryUseCase})
      : _getHistoryUseCase = getHistoryUseCase,
        super(const NotificationHistoryLoading());

  Future<void> load() async {
    emit(const NotificationHistoryLoading());
    final result = await _getHistoryUseCase(const NoParams());
    result.fold(
      (f) => emit(NotificationHistoryError(message: f.message)),
      (items) => emit(NotificationHistoryLoaded(items: items)),
    );
  }
}
