import 'dart:convert';
import 'package:flutter/services.dart';

/// Entrada del class_mapping: raw label + nombres en español.
class LabelEntry {
  final String raw;
  final String crop;
  final String disease;
  const LabelEntry({required this.raw, required this.crop, required this.disease});
}

/// Carga el class_mapping.json y provee mapeo índice → LabelEntry con nombres en español.
///
/// Formato JSON: Map de raw_label → índice de clase.
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

  // ── Tablas de traducción ────────────────────────────────────────────────────

  /// Traducción de nombres de cultivo (inglés → español).
  static const Map<String, String> _cultivoEs = {
    'Apple':                   'Manzano',
    'Blueberry':               'Arándano',
    'Cherry (including sour)': 'Cerezo (incluye agrio)',
    'Citrus':                  'Cítrico',
    'Corn (maize)':            'Maíz',
    'Grape':                   'Vid',
    'Orange':                  'Naranja',
    'Peach':                   'Durazno',
    'Pepper, bell':            'Pimiento morrón',
    'Potato':                  'Papa',
    'Raspberry':               'Frambuesa',
    'Soybean':                 'Soya',
    'Squash':                  'Calabacín',
    'Strawberry':              'Fresa',
    'Tomato':                  'Tomate',
  };

  /// Traducción de nombres de enfermedad/condición (inglés → español).
  static const Map<String, String> _enfermedadEs = {
    // Condiciones saludables (todas → Saludable para que el status-check funcione)
    'healthy':          'Saludable',
    'Healthy':          'Saludable',
    'Healthy Leaf':     'Saludable',
    'Buenos':           'Saludable',   // Frijol_Buenos = frijol sano

    // Condición dañada
    'Danados':          'Dañados',

    // Enfermedades — Manzano
    'Apple scab':               'Sarna del manzano',
    'Black rot':                'Pudrición negra',
    'Cedar apple rust':         'Roya del manzano',

    // Enfermedades — Calabaza
    'Bacterial Leaf Spot':      'Mancha bacteriana foliar',
    'Downy Mildew':             'Mildiu velloso',
    'Mosaic Disease':           'Enfermedad del mosaico',
    'Powdery Mildew':           'Oídio',

    // Enfermedades — Cítricos (sin prefijo de cultivo)
    'Black spot':               'Mancha negra',
    'Canker':                   'Cancro cítrico',
    'Greening':                 'Enverdecimiento (HLB)',
    'Melanose':                 'Melanosis cítrica',

    // Enfermedades — Cerezo
    'Powdery mildew':           'Oídio',

    // Enfermedades — Maíz
    'Cercospora leaf spot Gray leaf spot': 'Mancha foliar por Cercospora',
    'Common rust':              'Roya común',

    // Enfermedades — Maíz continuación
    'Northern Leaf Blight':     'Tizón norteño foliar',

    // Enfermedades — Vid
    'Esca (Black Measles)':                 'Esca (sarampión negro)',
    'Leaf blight (Isariopsis Leaf Spot)':   'Tizón foliar (Isariopsis)',

    // Enfermedades — Naranja
    'Haunglongbing (Citrus greening)': 'Huanglongbing (enverdecimiento cítrico)',

    // Enfermedades — Durazno / Pimiento / Papa
    'Bacterial spot':           'Mancha bacteriana',
    'Early blight':             'Tizón temprano',
    'Late blight':              'Tizón tardío',

    // Enfermedades — Tomate
    'Leaf Mold':                    'Moho foliar',
    'Septoria leaf spot':           'Mancha septoriana foliar',
    'Spider mites Two-spotted spider mite': 'Araña roja (ácaro bimaculado)',
    'Target Spot':                  'Mancha diana',
    'Tomato Yellow Leaf Curl Virus': 'Virus del rizado amarillo del tomate',
    'Tomato mosaic virus':          'Virus del mosaico del tomate',

    // Enfermedades — Fresa
    'Leaf scorch':              'Quemadura foliar',
  };

  // ── Parseo y traducción ─────────────────────────────────────────────────────

  /// Parsea el raw label y devuelve un LabelEntry con nombres en español.
  ///
  /// Formatos soportados:
  ///   "Apple___Apple_scab"           → Manzano / Sarna del manzano
  ///   "Calabaza_Bacterial Leaf Spot" → Calabaza / Mancha bacteriana foliar
  ///   "Black spot"                   → Desconocido / Mancha negra
  static LabelEntry _parseRawLabel(String raw) {
    String cropRaw;
    String diseaseRaw;

    // Separador PlantVillage: triple guion bajo
    if (raw.contains('___')) {
      final parts = raw.split('___');
      cropRaw    = _clean(parts[0]);
      diseaseRaw = _clean(parts.sublist(1).join(' '));
    } else {
      final underscoreIdx = raw.indexOf('_');
      if (underscoreIdx > 0) {
        // Separador simple: primer guion bajo
        cropRaw    = _clean(raw.substring(0, underscoreIdx));
        diseaseRaw = _clean(raw.substring(underscoreIdx + 1));
      } else {
        // Sin separador: etiqueta completa = enfermedad sin cultivo conocido
        cropRaw    = 'Desconocido';
        diseaseRaw = _clean(raw);
      }
    }

    // Aplicar traducciones; si no hay entrada en el mapa, conservar el valor limpio
    final cropEs    = _cultivoEs[cropRaw] ?? cropRaw;
    final diseaseEs = _enfermedadEs[diseaseRaw] ?? diseaseRaw;

    return LabelEntry(raw: raw, crop: cropEs, disease: diseaseEs);
  }

  /// Reemplaza guiones bajos por espacios y elimina espacios sobrantes.
  static String _clean(String s) => s.replaceAll('_', ' ').trim();
}
