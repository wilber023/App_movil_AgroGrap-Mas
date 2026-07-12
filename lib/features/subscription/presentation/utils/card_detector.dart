import 'dart:math';

// Ver API.md > "Detector de tipo de tarjeta".
enum CardType { visa, mastercard, amex, discover, unknown }

abstract final class CardDetector {
  CardDetector._();

  /// Detecta el tipo de tarjeta a partir del numero (parcial o completo).
  static CardType detect(String number) {
    final n = number.replaceAll(RegExp(r'[\s\-]'), '');
    if (n.isEmpty) return CardType.unknown;

    if (RegExp(r'^3[47]').hasMatch(n)) return CardType.amex;
    if (n.startsWith('4')) return CardType.visa;
    if (RegExp(r'^5[1-5]').hasMatch(n)) return CardType.mastercard;
    if (RegExp(r'^2(2[2-9][1-9]|[3-6]\d\d|7[01]\d|720)').hasMatch(n)) {
      return CardType.mastercard;
    }
    if (RegExp(r'^(6011|65|64[4-9])').hasMatch(n)) return CardType.discover;

    return CardType.unknown;
  }

  /// Formatea el numero con espacios: 4-4-4-4 (Visa/MC) o 4-6-5 (Amex).
  static String format(String raw, CardType type) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (type == CardType.amex) {
      return [
        digits.substring(0, min(4, digits.length)),
        if (digits.length > 4) digits.substring(4, min(10, digits.length)),
        if (digits.length > 10) digits.substring(10, min(15, digits.length)),
      ].join(' ');
    }
    final groups = <String>[];
    for (var i = 0; i < digits.length; i += 4) {
      groups.add(digits.substring(i, min(i + 4, digits.length)));
    }
    return groups.join(' ');
  }

  /// Maximo de digitos segun el tipo.
  static int maxDigits(CardType type) => type == CardType.amex ? 15 : 16;

  /// Nombre para mostrar en la UI.
  static String label(CardType type) => switch (type) {
        CardType.visa => 'Visa',
        CardType.mastercard => 'Mastercard',
        CardType.amex => 'American Express',
        CardType.discover => 'Discover',
        CardType.unknown => '',
      };
}
