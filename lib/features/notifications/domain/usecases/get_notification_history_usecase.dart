import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/push_notification_entry_entity.dart';
import '../repositories/notification_history_repository.dart';

class GetNotificationHistoryUseCase implements UseCase<List<PushNotificationEntryEntity>, NoParams> {
  final NotificationHistoryRepository repository;
  const GetNotificationHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<PushNotificationEntryEntity>>> call(NoParams params) {
    return repository.getHistory();
  }
}
