// =============================================================================
// AgroGraph-MAS -- Monitor de Conectividad
// =============================================================================
// Abstraccion para verificar el estado de la red.
// Soporte critico para la filosofia Offline-First del Design System.
// =============================================================================

import 'package:connectivity_plus/connectivity_plus.dart';

/// Contrato para verificar la disponibilidad de red.
abstract interface class NetworkInfo {
  /// Retorna `true` si el dispositivo tiene conexion a internet.
  Future<bool> get isConnected;

  /// Stream de cambios de conectividad para reaccionar en tiempo real.
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
}

/// Implementacion concreta de [NetworkInfo] usando connectivity_plus.
///
/// Verifica si hay alguna interfaz de red activa (WiFi, celular, Ethernet).
/// No realiza ping al servidor; solo verifica la presencia de interfaz
/// (rapido y sin bloqueo de UI).
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfoImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _hasActiveConnection(results);
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  /// Verifica si alguno de los resultados indica una conexion activa.
  bool _hasActiveConnection(List<ConnectivityResult> results) {
    return results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);
  }
}
