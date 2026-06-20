import 'package:equatable/equatable.dart';

enum ActivityStatus {
  pending,
  completed,
  postponed
}

class CropActivityEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final int weekNumber;
  final ActivityStatus status;
  final DateTime scheduledDate;
  final bool isPendingSync;

  const CropActivityEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.weekNumber,
    required this.status,
    required this.scheduledDate,
    this.isPendingSync = false,
  });

  CropActivityEntity copyWith({
    String? id,
    String? title,
    String? description,
    int? weekNumber,
    ActivityStatus? status,
    DateTime? scheduledDate,
    bool? isPendingSync,
  }) {
    return CropActivityEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      weekNumber: weekNumber ?? this.weekNumber,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        weekNumber,
        status,
        scheduledDate,
        isPendingSync,
      ];
}
