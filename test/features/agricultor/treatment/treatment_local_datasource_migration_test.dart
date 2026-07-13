import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:agrograp_movil/features/agricultor/treatment/data/datasources/treatment_local_datasource.dart';

/// Verifica qué pasa con un dispositivo que ya tenía datos guardados en el
/// formato ANTERIOR a este sprint (antes de conectar el backend real de
/// agenda): flags por diagnóstico (`agenda_added_$id`), completions por
/// paso (`treatment_$id`), overrides de reprogramación
/// (`reschedule_${id}_$stepId`) y recordatorios (`reminders_$id`), todos
/// escritos directamente en la caja Hive `agenda_box` -- sin pasar por
/// `TreatmentLocalDataSource` (esa clase no existía con esa forma).
///
/// Usa una caja Hive REAL en un directorio temporal (no un fake) para que
/// la prueba sea fiel a lo que Hive hace de verdad con datos preexistentes.
void main() {
  late Directory tempDir;
  late Box<String> agendaBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('treatment_migration_test');
    Hive.init(tempDir.path);
    agendaBox = await Hive.openBox<String>('agenda_box');
  });

  tearDown(() async {
    await agendaBox.close();
    await tempDir.delete(recursive: true);
  });

  test(
    'caja con datos del formato viejo (sin treatment_local_state) -> '
    'getState() no revienta, devuelve null (no hay plan activo migrado), '
    'y los datos viejos quedan intactos sin leerse ni borrarse',
    () async {
      // Exactamente las claves que escribía el código anterior a este
      // sprint (diagnosis_result_page.dart._addToAgenda() +
      // TreatmentLocalDataSourceImpl vieja).
      await agendaBox.put('agenda_added_diag123', 'true');
      await agendaBox.put('treatment_diag123', '{"step_1":"2026-01-01T08:00:00.000"}');
      await agendaBox.put('reschedule_diag123_step_2', '2026-02-01T00:00:00.000');
      await agendaBox.put('reminders_diag123', 'true');

      final datasource = TreatmentLocalDataSourceImpl(agendaBox: agendaBox);

      expect(() => datasource.getState(), returnsNormally);
      expect(datasource.getState(), isNull);

      // Las claves viejas siguen ahí tal cual, sin tocarse -- no se pierden,
      // solo quedan sin usar por el código nuevo.
      expect(agendaBox.get('agenda_added_diag123'), 'true');
      expect(agendaBox.get('treatment_diag123'), isNotNull);
      expect(agendaBox.get('reschedule_diag123_step_2'), isNotNull);
      expect(agendaBox.get('reminders_diag123'), 'true');
    },
  );

  test(
    'después de generar un plan nuevo, guardar/leer el estado nuevo no '
    'colisiona con las claves viejas que puedan seguir en la misma caja',
    () async {
      await agendaBox.put('agenda_added_diag123', 'true');

      final datasource = TreatmentLocalDataSourceImpl(agendaBox: agendaBox);
      await datasource.saveState({
        'diagnosisId': 'diag456',
        'diseaseName': 'Tizón tardío',
        'createdAt': DateTime(2026, 7, 12).toIso8601String(),
      });

      final state = datasource.getState();
      expect(state, isNotNull);
      expect(state!['diagnosisId'], 'diag456');
      // La clave vieja sigue intacta, sin relación con el estado nuevo.
      expect(agendaBox.get('agenda_added_diag123'), 'true');
    },
  );
}
