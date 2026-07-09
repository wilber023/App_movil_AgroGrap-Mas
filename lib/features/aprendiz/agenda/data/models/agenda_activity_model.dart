import '../../domain/entities/agenda_activity_entity.dart';

class AgendaActivityModel extends AgendaActivityEntity {
  const AgendaActivityModel({
    required super.id,
    required super.title,
    required super.description,
    required super.scheduledDate,
    required super.weekNumber,
    required super.status,
    super.checklist,
    super.category,
    super.isPendingSync,
  });

  factory AgendaActivityModel.fromJson(Map<String, dynamic> json) {
    return AgendaActivityModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      checklist: (json['checklist'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      weekNumber: json['weekNumber'] as int,
      status: AgendaActivityStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AgendaActivityStatus.pending,
      ),
      category: AgendaActivityCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AgendaActivityCategory.generic,
      ),
      isPendingSync: json['isPendingSync'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'checklist': checklist,
      'scheduledDate': scheduledDate.toIso8601String(),
      'weekNumber': weekNumber,
      'status': status.name,
      'category': category.name,
      'isPendingSync': isPendingSync,
    };
  }

  factory AgendaActivityModel.fromEntity(AgendaActivityEntity entity) {
    return AgendaActivityModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      checklist: entity.checklist,
      scheduledDate: entity.scheduledDate,
      weekNumber: entity.weekNumber,
      status: entity.status,
      category: entity.category,
      isPendingSync: entity.isPendingSync,
    );
  }

  @override
  AgendaActivityModel copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? checklist,
    DateTime? scheduledDate,
    int? weekNumber,
    AgendaActivityStatus? status,
    AgendaActivityCategory? category,
    bool? isPendingSync,
  }) {
    return AgendaActivityModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      checklist: checklist ?? this.checklist,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      weekNumber: weekNumber ?? this.weekNumber,
      status: status ?? this.status,
      category: category ?? this.category,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }
}
