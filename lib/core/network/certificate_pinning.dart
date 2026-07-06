// =============================================================================
// Core -- Certificate / Identity Pinning (punto de extensión)
// =============================================================================
// Capa: Core / Network
// MASVS-NETWORK (recomendado): el pinning de certificados solo tiene
// sentido cuando el servidor expone TLS — hoy los 4 microservicios de
// AgroGraph (Usuarios, Cultivos, LLM/RAG, Productos) se sirven por HTTP
// plano sobre IPs de EC2, sin certificado que fijar. Este archivo deja
// preparado el punto de integración: en cuanto backend exponga HTTPS con
// un certificado propio, basta con:
//   1. Completar `trustedFingerprintsSha256` con el SHA-256 del
//      certificado/llave pública real de cada host.
//   2. Llamar a [CertificatePinning.attach] sobre el `Dio` correspondiente
//      en `injection_container.dart`.
// Mientras el fingerprint esté vacío, `attach` es un no-op explícito para
// no romper las conexiones HTTP actuales.
// =============================================================================

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

abstract final class CertificatePinning {
  /// host → huella SHA-256 esperada del certificado (vacío = pinning inactivo).
  static const Map<String, String> trustedFingerprintsSha256 = {
    // '174.129.218.190': 'AA:BB:...',
  };

  static void attach(Dio dio) {
    if (trustedFingerprintsSha256.isEmpty) return; // sin TLS que fijar aún

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) {
        final expected = trustedFingerprintsSha256[host];
        if (expected == null) return false;
        final actual = sha256.convert(cert.der).toString();
        return actual == expected;
      };
      return client;
    };
  }
}
