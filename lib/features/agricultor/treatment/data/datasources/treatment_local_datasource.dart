import 'dart:convert';

import 'package:hive/hive.dart';

/// Capa local de Treatment: guarda el estado que NO viene del backend de
/// agenda (metadatos del diagnóstico que originó el plan, overrides de
/// reprogramación de fecha -- el backend no soporta mover una actividad a
/// una fecha arbitraria -- y marcas de completado con hora local, más el
/// flag de recordatorios). El overview real (actividades/estado) lo maneja
/// `AgendaRepository` (ver `TreatmentRepositoryImpl`); esta clase solo
/// guarda el complemento local.
abstract interface class TreatmentLocalDataSource {
  Map<String, dynamic>? getState();
  Future<void> saveState(Map<String, dynamic> state);
}

class TreatmentLocalDataSourceImpl implements TreatmentLocalDataSource {
  final Box<String> agendaBox;

  static const _stateKey = 'treatment_local_state';

  const TreatmentLocalDataSourceImpl({required this.agendaBox});

  @override
  Map<String, dynamic>? getState() {
    final raw = agendaBox.get(_stateKey);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveState(Map<String, dynamic> state) async {
    await agendaBox.put(_stateKey, jsonEncode(state));
  }
}
