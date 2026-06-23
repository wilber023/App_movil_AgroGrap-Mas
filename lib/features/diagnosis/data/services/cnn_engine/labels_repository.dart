import 'dart:convert';
import 'package:flutter/services.dart';

/// Entrada del class_mapping: raw label + nombres ya parseados en español.
class LabelEntry {
  final String raw;
  final String crop;
  final String disease;
  const LabelEntry({required this.raw, required this.crop, required this.disease});
}

/// Carga el class_mapping.json y provee mapeo índice → LabelEntry.
/// Formato esperado: lista de objetos [{raw, crop, disease}, ...]
/// La posición en la lista = índice de salida del modelo TFLite.
class LabelsRepository {
  LabelsRepository._();
  static final LabelsRepository instance = LabelsRepository._();

  Map<int, LabelEntry>? _labelMap;

  Map<int, LabelEntry> get labelMap {
    assert(_labelMap != null, 'LabelsRepository.load() debe llamarse primero');
    return _labelMap!;
  }

  bool get isLoaded => _labelMap != null;

  Future<void> load() async {
    if (_labelMap != null) return;
    final raw = await rootBundle.loadString('assets/models/class_mapping.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    _labelMap = {
      for (int i = 0; i < decoded.length; i++)
        i: LabelEntry(
          raw:     decoded[i]['raw']     as String,
          crop:    decoded[i]['crop']    as String,
          disease: decoded[i]['disease'] as String,
        ),
    };
  }

  LabelEntry getEntry(int index) =>
      _labelMap?[index] ?? LabelEntry(raw: 'idx_$index', crop: 'Desconocido', disease: 'Desconocido');
}