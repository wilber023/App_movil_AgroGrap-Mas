import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/notification_preferences_entity.dart';
import '../repositories/notification_history_repository.dart';

class GetNotificationPreferencesUseCase implements UseCase<NotificationPreferencesEntity, NoParams> {
  final NotificationHistoryRepository repository;
  const GetNotificationPreferencesUseCase(this.repository);

  @override
  Future<Either<Failure, NotificationPreferencesEntity>> call(NoParams params) {
    return repository.getPreferences();
  }
}

class SaveNotificationPreferencesUseCase implements UseCase<void, NotificationPreferencesEntity> {
  final NotificationHistoryRepository repository;
  const SaveNotificationPreferencesUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NotificationPreferencesEntity params) {
    return repository.savePreferences(params);
  }
}
