class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException({required this.message, this.statusCode});

  @override
  String toString() => 'NetworkException: $message (statusCode: $statusCode)';
}

class UnauthorizedException extends NetworkException {
  UnauthorizedException({super.message = 'No autorizado'}) : super(statusCode: 401);
}

class ValidationException extends NetworkException {
  ValidationException({super.message = 'Error de validación'}) : super(statusCode: 400);
}

class ServerException extends NetworkException {
  ServerException({super.message = 'Error interno del servidor'}) : super(statusCode: 500);
}
