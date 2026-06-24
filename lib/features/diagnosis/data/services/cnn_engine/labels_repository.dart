import 'dart:convert';
import 'package:flutter/services.dart';

/// Entrada del class_mapping: raw label + nombres parseados.
class LabelEntry {
  final String raw;
  final String crop;
  final String disease;
  const LabelEntry({required this.raw, required this.crop, required this.disease});
}

/// Carga el class_mapping.json y provee mapeo índice → LabelEntry.
///
/// Formato soportado: Map de raw_label → índice de clase.
/// Ejemplo: {"Apple___Apple_scab": 0, "Calabaza_Healthy Leaf": 8, ...}
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
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    // JSON es {raw_label: class_index} — invertir a {class_index: LabelEntry}
    _labelMap = {};
    decoded.forEach((rawLabel, indexValue) {
      final idx = indexValue as int;
      _labelMap![idx] = _parseRawLabel(rawLabel);
    });
  }

  LabelEntry getEntry(int index) =>
      _labelMap?[index] ??
      LabelEntry(raw: 'idx_$index', crop: 'Desconocido', disease: 'Desconocido');

  /// Extrae crop y disease del raw label.
  ///
  /// Formatos soportados:
  ///   "Apple___Apple_scab"           → crop: "Apple",      disease: "Apple scab"
  ///   "Calabaza_Bacterial Leaf Spot" → crop: "Calabaza",   disease: "Bacterial Leaf Spot"
  ///   "Black spot"                   → crop: "Desconocido",disease: "Black spot"
  static LabelEntry _parseRawLabel(String raw) {
    // Separador PlantVillage: triple guion bajo
    if (raw.contains('___')) {
      final parts   = raw.split('___');
      final crop    = _clean(parts[0]);
      final disease = _clean(parts.sublist(1).join(' '));
      return LabelEntry(raw: raw, crop: crop, disease: disease);
    }

    // Separador simple: primer guion bajo
    final underscoreIdx = raw.indexOf('_');
    if (underscoreIdx > 0) {
      final crop    = _clean(raw.substring(0, underscoreIdx));
      final disease = _clean(raw.substring(underscoreIdx + 1));
      return LabelEntry(raw: raw, crop: crop, disease: disease);
    }

    // Sin separador: etiqueta completa = nombre de enfermedad
    return LabelEntry(raw: raw, crop: 'Desconocido', disease: _clean(raw));
  }

  static String _clean(String s) => s.replaceAll('_', ' ').trim();
}
