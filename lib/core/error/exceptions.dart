// =============================================================================
// AgroGraph-MAS -- Excepciones de la Capa de Datos
// =============================================================================

/// Excepcion lanzada cuando el servidor retorna un error.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Excepcion lanzada cuando falla la lectura/escritura en cache local.
class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}
