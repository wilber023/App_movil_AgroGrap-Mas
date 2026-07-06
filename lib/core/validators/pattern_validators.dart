// =============================================================================
// Core -- Validadores de Patrones y Reglas Específicas
// =============================================================================
// Capa: Core / Validators
// Reglas concretas para campos particulares: numero de tarjeta (Luhn) y
// fortaleza de contraseña.
// =============================================================================

class PatternValidators {
  // Algoritmo de Luhn para validar numero de tarjeta (pagos B2B/B2G)
  static bool isValidCardNumber(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  // Fortaleza de contraseña: min. 8 caracteres, mayuscula, minuscula, numero y simbolo.
  // Uso: creacion/cambio de contraseña (registro), NUNCA en el login — el
  // login debe aceptar cualquier contraseña ya existente para que el
  // backend sea quien decida si las credenciales son correctas.
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
    final hasMinLength = value.length >= 8;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasLower = RegExp(r'[a-z]').hasMatch(value);
    final hasDigit = RegExp(r'\d').hasMatch(value);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(value);
    if (!hasMinLength) return 'Mínimo 8 caracteres';
    if (!hasUpper || !hasLower) return 'Debe combinar mayúsculas y minúsculas';
    if (!hasDigit) return 'Debe incluir al menos un número';
    if (!hasSpecial) return 'Debe incluir al menos un carácter especial';
    return null;
  }
}
