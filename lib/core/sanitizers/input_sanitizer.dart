// =============================================================================
// Core -- Sanitizador de Entradas
// =============================================================================
// Capa: Core / Sanitizers
// Subconjunto de técnicas de sanitización aplicables al cliente Flutter:
// limpieza (trim/normalize), filtrado (whitelisting) y escapado de HTML
// antes de renderizar contenido dinámico (ej. texto del LLM agronómico
// mostrado en un WebView).
// =============================================================================

import 'dart:convert';

class InputSanitizer {
  static String trimAndNormalize(String value) => value.trim();

  // URL-encode de query params antes de construir la petición.
  static String urlEncode(String value) => Uri.encodeQueryComponent(value);

  // Base64 para binarios (ej. imagen del diagnóstico CNN) enviados en JSON.
  static String base64EncodeBytes(List<int> bytes) => base64Encode(bytes);

  // Whitelisting simple para usernames
  static String whitelistAlphanumeric(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
  }

  // Escapado antes de mostrar contenido dinámico en un WebView/HTML
  static String escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }
}
