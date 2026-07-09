import 'package:equatable/equatable.dart';

/// Estado de una actividad de la Agenda del Aprendiz.
enum AgendaActivityStatus { pending, completed, postponed }

/// Categoria visual/funcional de una actividad, usada para elegir el icono
/// y el color de acento en la lista de "Proximas tareas".
enum AgendaActivityCategory { inspection, tracking, treatment, generic }

/// Actividad programada dentro de la Agenda del Aprendiz.
///
/// [checklist] son las acciones recomendadas para el dia de la actividad
/// (lo que la tarjeta "Hoy" muestra como lista de verificacion).
class AgendaActivityEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final List<String> checklist;
  final DateTime scheduledDate;
  final int weekNumber;
  final AgendaActivityStatus status;
  final AgendaActivityCategory category;
  final bool isPendingSync;

  const AgendaActivityEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledDate,
    required this.weekNumber,
    required this.status,
    this.checklist = const [],
    this.category = AgendaActivityCategory.generic,
    this.isPendingSync = false,
  });

  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  AgendaActivityEntity copyWith({
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
    return AgendaActivityEntity(
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

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        checklist,
        scheduledDate,
        weekNumber,
        status,
        category,
        isPendingSync,
      ];
}
