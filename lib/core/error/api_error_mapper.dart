// =============================================================================
// Core -- Mapeador de Errores de API
// =============================================================================
// Capa: Data (helper puro, sin dependencias de framework)
// Los errores de validación/red no deben revelar información sensible del
// backend al usuario final (ej. distinguir "el usuario no existe" de
// "la contraseña es incorrecta", ni mostrar mensajes crudos de excepción
// o stack traces). Solo se aplica a fallos ORIGINADOS en el servidor
// (ServerFailure): los mensajes ya redactados por la propia app (sesión
// expirada, sin conexión, rol incorrecto) se preservan tal cual.
// =============================================================================

class ApiErrorMapper {
  const ApiErrorMapper._();

  static const String genericMessage =
      'No pudimos procesar tu solicitud. Verifica tus datos e intenta de nuevo.';

  /// Códigos HTTP para los que es seguro mostrar un mensaje algo más
  /// específico sin filtrar detalle interno del backend.
  static String toUserMessage(Object error, {int? statusCode}) {
    switch (statusCode) {
      case 400:
      case 422:
        return 'Revisa los datos ingresados e intenta de nuevo.';
      case 401:
        return 'Usuario o contraseña incorrectos.';
      case 403:
        return 'No tienes permisos para realizar esta acción.';
      case 404:
        return 'No encontramos lo que buscas.';
      case 409:
        return 'Ese registro ya existe.';
      default:
        return genericMessage;
    }
  }
}
