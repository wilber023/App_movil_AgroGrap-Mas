import '../../domain/entities/phytosanitary_alert_entity.dart';

/// Fuente de la alerta fitosanitaria mientras el backend no expone el
/// endpoint correspondiente: entrega siempre el estado neutral real
/// (`PhytosanitaryAlertLevel.none`, "No existen alertas para tu región") —
/// nunca un dato inventado, y sin intentar ninguna llamada de red hacia un
/// endpoint que aun no existe.
abstract class PhytosanitaryAlertLocalDataSource {
  Future<PhytosanitaryAlertEntity> getNeutralAlert();
}

class PhytosanitaryAlertLocalDataSourceImpl implements PhytosanitaryAlertLocalDataSource {
  @override
  Future<PhytosanitaryAlertEntity> getNeutralAlert() async {
    return PhytosanitaryAlertEntity.none;
  }
}
