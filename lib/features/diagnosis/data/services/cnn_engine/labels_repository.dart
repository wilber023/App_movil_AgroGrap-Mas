import 'dart:convert';
import 'package:flutter/services.dart';

/// Carga el archivo assets/models/labels.json y provee el mapeo índice → etiqueta CNN.
class LabelsRepository {
  LabelsRepository._();
  static final LabelsRepository instance = LabelsRepository._();

  Map<int, String>? _labelMap;

  Map<int, String> get labelMap {
    assert(_labelMap != null, 'LabelsRepository.load() debe llamarse primero');
    return _labelMap!;
  }

  bool get isLoaded => _labelMap != null;

  Future<void> load() async {
    if (_labelMap != null) return;
    final raw = await rootBundle.loadString('assets/models/labels.json');
    final Map<String, dynamic> parsed = jsonDecode(raw) as Map<String, dynamic>;
    _labelMap = {
      for (final entry in parsed.entries)
        int.parse(entry.key): entry.value as String
    };
  }

  String getLabel(int index) =>
      _labelMap?[index] ?? 'Unknown_$index';
}
