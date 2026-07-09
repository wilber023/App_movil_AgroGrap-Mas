import 'package:equatable/equatable.dart';

import 'agenda_activity_entity.dart';
import 'agenda_crop_context_entity.dart';

/// Agregado que la pantalla de Agenda necesita para renderizarse completa:
/// el contexto del cultivo activo y todas sus actividades programadas.
class AgendaOverviewEntity extends Equatable {
  final AgendaCropContextEntity cropContext;
  final List<AgendaActivityEntity> activities;

  const AgendaOverviewEntity({
    required this.cropContext,
    required this.activities,
  });

  @override
  List<Object?> get props => [cropContext, activities];
}
