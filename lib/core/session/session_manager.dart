import 'dart:async';

/// Unico punto de comunicacion para "la sesion dejo de ser valida".
///
/// No guarda tokens, no decide nada, no navega: solo emite el evento para
/// que quien este escuchando (el arbol de navegacion raiz) reaccione.
/// Cualquier parte de la app puede notificar (ej. un interceptor de Dio)
/// sin conocer quien escucha, y quien escucha no necesita saber quien
/// disparo el evento.
class SessionManager {
  SessionManager._internal();
  static final SessionManager instance = SessionManager._internal();

  final _controller = StreamController<void>.broadcast();

  Stream<void> get onSessionInvalidated => _controller.stream;

  void notifySessionInvalidated() {
    _controller.add(null);
  }
}
