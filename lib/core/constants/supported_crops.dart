/// Cultivos soportados por el modelo CNN de diagnostico (33 clases, ver
/// `assets/models/class_mapping.json`). Es el unico catalogo permitido al
/// registrar un cultivo, tanto para el perfil Agricultor (parcelas) como
/// para el perfil Aprendiz (cultivo de practica) -- ambos filtran el mismo
/// catalogo real del microservicio de Cultivos (`GET /cultivos`) contra este
/// set para no ofrecer cultivos que el CNN no sabe diagnosticar.
abstract final class SupportedCrops {
  SupportedCrops._();

  static const Set<String> names = {
    'Calabaza',
    'Frijol',
    'Maíz',
    'Papa',
    'Tomate',
  };

  static const Map<String, String> _emojiByName = {
    'Calabaza': '🍈',
    'Frijol': '🫘',
    'Maíz': '🌽',
    'Papa': '🥔',
    'Tomate': '🍅',
  };

  static String emojiFor(String cropName) => _emojiByName[cropName] ?? '🌿';
}
