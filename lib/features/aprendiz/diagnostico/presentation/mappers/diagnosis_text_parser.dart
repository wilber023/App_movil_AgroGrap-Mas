/// Utilidad pura (sin Flutter) para convertir un parrafo libre — como
/// `tratamiento`/`prevencion` de `LlmResponseEntity`, que siguen llegando
/// como texto — en una lista corta de items aptos para un checklist visual.
///
/// No modifica el contrato de la API: solo reinterpreta texto ya recibido.
abstract final class DiagnosisTextParser {
  DiagnosisTextParser._();

  static final _bulletMarker = RegExp(r'(?:\r?\n|^)\s*(?:[-•*]|\d{1,2}[.)])\s+');
  static final _sentenceSplit = RegExp(r'(?<=[.;])\s+');

  /// Divide [text] en items cortos: si el texto ya trae marcadores de lista
  /// (saltos de linea, "- ", "• ", "1.", "2)") se respeta esa segmentacion;
  /// si no, se corta por oraciones. Se descartan fragmentos triviales y se
  /// limita a [maxItems] para que el resultado sea un checklist, no un
  /// parrafo.
  static List<String> splitIntoItems(String text, {int maxItems = 5}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];

    var parts = trimmed.split(_bulletMarker);
    if (parts.length <= 1) {
      parts = trimmed.split(_sentenceSplit);
    }

    final items = <String>[];
    for (final raw in parts) {
      final cleaned = _clean(raw);
      if (cleaned.length < 10) continue;
      items.add(cleaned);
      if (items.length >= maxItems) break;
    }

    // Si el corte no produjo nada util (texto sin puntuacion clara), se usa
    // el parrafo completo como unico item en vez de perder la informacion.
    if (items.isEmpty) {
      final fallback = _clean(trimmed);
      if (fallback.isNotEmpty) return [fallback];
    }

    return items;
  }

  static String _clean(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    while (s.endsWith('.') || s.endsWith(';') || s.endsWith(',')) {
      s = s.substring(0, s.length - 1).trim();
    }
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
