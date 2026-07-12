import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/push_notification_entry_entity.dart';
import '../repositories/notification_history_repository.dart';

class SaveNotificationUseCase implements UseCase<void, PushNotificationEntryEntity> {
  final NotificationHistoryRepository repository;
  const SaveNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(PushNotificationEntryEntity params) {
    return repository.saveReceived(params);
  }
}
