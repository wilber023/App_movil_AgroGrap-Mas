import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../../core/di/injection_container.dart';

/// Cuenta los diagnósticos guardados localmente (Hive) para una parcela.
/// Puramente de presentación: no es una fuente de verdad del dominio, solo
/// un conteo informativo mostrado en la tarjeta de [ParcelsPage].
int countLocalDiagnosesFor(String parcelId) {
  try {
    final box = sl<Box<String>>(instanceName: 'diagnosisBox');
    var count = 0;
    for (final raw in box.values) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        if (m['parcelId'] == parcelId) count++;
      } catch (_) {}
    }
    return count;
  } catch (_) {
    return 0;
  }
}
