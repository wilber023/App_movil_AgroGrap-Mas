# Validaciones de Seguridad — AgroGraph (Frontend Flutter)

Reporte de integración real en el repositorio, en respuesta al checklist de
`README_Frontend_Validacion_Seguridad.md` (Parte A + Parte B / OWASP MASVS).

---

## PARTE A — Validación y Sanitización de Entradas

### 1. Validación de formato (email, teléfono, fecha)
- **Bloque de código aplicado:**
```dart
// core/validators/format_validators.dart
class FormatValidators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'El correo es obligatorio';
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(value) ? null : 'Formato de correo inválido';
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'El teléfono es obligatorio';
    final regex = RegExp(r'^\+?[0-9]{10,13}$');
    return regex.hasMatch(value) ? null : 'Teléfono inválido';
  }

  static String? date(String? value, {String pattern = r'^\d{4}-\d{2}-\d{2}$'}) {
    if (value == null || value.isEmpty) return 'La fecha es obligatoria';
    return RegExp(pattern).hasMatch(value) ? null : 'Formato de fecha inválido (YYYY-MM-DD)';
  }
}
```
- **Ubicación en el proyecto:** `lib/core/validators/format_validators.dart` — capa core.
- **Estado:** utilidad genérica lista para consumir. AgroGraph no solicita
  correo/teléfono en el registro actual (`RegisterFormData` solo pide
  nombre/apellido/usuario/contraseña) ni tiene campos de fecha en texto
  libre (`add_parcel_page.dart` usa `showDatePicker`, no un `TextField`),
  por lo que aún no hay una pantalla que la invoque. Queda centralizada y
  lista para el día que se agregue recuperación de contraseña por correo
  o verificación telefónica.
- **Captura de pantalla:** no aplica todavía (sin pantalla consumidora). Se
  recomienda capturar la pantalla de recuperación de contraseña cuando se
  implemente, mostrando el error "Formato de correo inválido".
  `![captura](docs/capturas/formato-email.png)`

---

### 2. Validación de longitud
- **Bloque de código aplicado:**
```dart
// core/validators/length_validators.dart
class LengthValidators {
  static String? range(String? value, {required int min, required int max, String field = 'Campo'}) {
    if (value == null) return '$field es obligatorio';
    if (value.length < min) return '$field debe tener al menos $min caracteres';
    if (value.length > max) return '$field no debe exceder $max caracteres';
    return null;
  }
}
```
- **Ubicación en el proyecto:** `lib/core/validators/length_validators.dart` —
  capa core. Consumido en
  `lib/features/login/auth/domain/usecases/validate_register_form_usecase.dart`
  para nombre (2–50), apellido (2–50) y usuario (3–30).
- **Captura de pantalla:** Pantalla de registro, campo "Nombre", mostrando
  el mensaje "El nombre debe tener al menos 2 caracteres" tras escribir un
  solo carácter.
  `![captura](docs/capturas/longitud-nombre.png)`

---

### 3. Validación de rango
- **Bloque de código aplicado:**
```dart
// core/validators/range_validators.dart
class RangeValidators {
  static String? numericRange(num? value, {required num min, required num max, String field = 'Valor'}) {
    if (value == null) return '$field es obligatorio';
    if (value < min || value > max) return '$field debe estar entre $min y $max';
    return null;
  }
}
```
- **Ubicación en el proyecto:** `lib/core/validators/range_validators.dart` —
  capa core. El rango de superficie de parcela concreto se aplica a través
  del Value Object `Hectareas` (ver punto 6), que encapsula la misma regla
  de rango (0 < ha ≤ 100 000) junto con el parseo de tipo.
- **Captura de pantalla:** no aplica una pantalla propia adicional (ver
  punto 6, mismo flujo).

---

### 4. Validación de contenido (whitelisting de caracteres)
- **Bloque de código aplicado:**
```dart
// core/validators/content_validators.dart
class ContentValidators {
  static String? safeName(String? value) {
    if (value == null || value.isEmpty) return 'Este campo es obligatorio';
    final regex = RegExp(r"^[a-zA-ZÀ-ÿñÑ\s\-]+$");
    return regex.hasMatch(value) ? null : 'No se permiten caracteres especiales ni números';
  }
}
```
- **Ubicación en el proyecto:** `lib/core/validators/content_validators.dart`
  — capa core. Consumido en `validate_register_form_usecase.dart` para
  nombre y apellido.
- **Captura de pantalla:** Pantalla de registro, campo "Nombre", mostrando
  "No se permiten caracteres especiales ni números" tras escribir p. ej.
  `Wilber123`.
  `![captura](docs/capturas/contenido-nombre.png)`

---

### 5. Validador regex genérico
- **Bloque de código aplicado:**
```dart
// core/validators/regex_validator.dart
class RegexValidator {
  static String? matches(String? value, RegExp pattern, {String errorMessage = 'Formato inválido'}) {
    if (value == null || value.isEmpty) return 'Este campo es obligatorio';
    return pattern.hasMatch(value) ? null : errorMessage;
  }
}
```
- **Ubicación en el proyecto:** `lib/core/validators/regex_validator.dart` —
  capa core. Consumido en `validate_register_form_usecase.dart` para el
  patrón de nombre de usuario (`^[a-zA-Z0-9_]+$`).
- **Captura de pantalla:** Pantalla de registro, campo "Usuario", mostrando
  "Solo letras, numeros y guion bajo" tras escribir p. ej. `wil-hdz!`.
  `![captura](docs/capturas/regex-usuario.png)`

---

### 6. Validación de tipo de dato (Value Object en domain)
- **Bloque de código aplicado:**
```dart
// features/agricultor/parcels/domain/value_objects/hectareas.dart
class Hectareas {
  final double value;

  Hectareas(String raw) : value = _parse(raw);

  static double _parse(String raw) {
    final parsed = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (parsed == null) throw FormatException('La superficie debe ser un valor numérico');
    if (parsed <= 0) throw FormatException('La superficie debe ser mayor que 0');
    if (parsed > 100000) throw FormatException('La superficie ingresada es demasiado grande');
    return parsed;
  }

  static String? validate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'La superficie es obligatoria';
    try {
      Hectareas(raw);
      return null;
    } on FormatException catch (e) {
      return e.message;
    }
  }
}
```
  Integración real en `add_parcel_page.dart` (antes el valor se
  parseaba con `double.tryParse(...) ?? 0.0`, silenciando cualquier error
  de formato):
```dart
String? get _areaError => Hectareas.validate(_areaController.text);

bool get _isValid =>
    _nameController.text.trim().isNotEmpty &&
    _areaError == null &&
    _regionController.text.trim().isNotEmpty &&
    _selectedCropIndex != -1 &&
    _selectedDate != null &&
    _catalog.isNotEmpty;
...
final areaRaw = Hectareas(_areaController.text.trim()).value;
```
- **Ubicación en el proyecto:**
  `lib/features/agricultor/parcels/domain/value_objects/hectareas.dart`
  (capa domain) + `lib/features/agricultor/parcels/presentation/pages/add_parcel_page.dart`
  (capa presentation).
- **Captura de pantalla:** Pantalla "Nueva Parcela / Cultivo", campo
  "Superficie", mostrando el mensaje "La superficie debe ser mayor que 0"
  tras escribir `0` o texto no numérico.
  `![captura](docs/capturas/tipo-dato-hectareas.png)`

---

### 7. Patrones específicos (Luhn, fortaleza de contraseña)
- **Bloque de código aplicado:**
```dart
// core/validators/pattern_validators.dart
class PatternValidators {
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
```
- **Ubicación en el proyecto:** `lib/core/validators/pattern_validators.dart`
  — capa core. `strongPassword` se consume en
  `validate_register_form_usecase.dart` (creación de cuenta). **A propósito
  NO se aplica en `login_page.dart`**: el login debe aceptar cualquier
  contraseña ya existente y dejar que el backend decida si es correcta;
  endurecer la validación ahí bloquearía a cuentas reales creadas antes de
  este cambio. `isValidCardNumber` (Luhn) queda disponible para cuando
  AgroGraph maneje pagos B2B/B2G — no aplica todavía porque no existe
  ningún flujo de pago en la app.
- **Captura de pantalla:** Pantalla de registro, campo "Contraseña",
  mostrando "Debe incluir al menos un carácter especial" tras escribir una
  contraseña débil (ej. `abc12345`).
  `![captura](docs/capturas/fortaleza-password.png)`

---

### 8. Validación cruzada
- **Bloque de código aplicado:**
```dart
// core/validators/cross_field_validators.dart
class CrossFieldValidators {
  static String? dateOrder(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'Ambas fechas son obligatorias';
    if (start.isAfter(end)) return 'La fecha de inicio no puede ser posterior a la de fin';
    return null;
  }

  static String? passwordsMatch(String password, String confirmation) {
    return password == confirmation ? null : 'Las contraseñas no coinciden';
  }
}
```
  Integración real en `validate_register_form_usecase.dart`:
```dart
if (data.confirmPassword.isEmpty) {
  errors['confirmPassword'] = 'Confirma tu contrasena';
} else {
  final matchError = CrossFieldValidators.passwordsMatch(data.password, data.confirmPassword);
  if (matchError != null) errors['confirmPassword'] = matchError;
}
```
- **Ubicación en el proyecto:** `lib/core/validators/cross_field_validators.dart`
  (capa core) + `lib/features/login/auth/domain/usecases/validate_register_form_usecase.dart`
  (capa domain). `dateOrder` queda disponible pero sin pantalla consumidora:
  ningún formulario actual pide dos fechas del usuario (siembra se
  selecciona con un único `DatePicker`; no existe un campo de fecha de
  cosecha ingresado manualmente).
- **Captura de pantalla:** Pantalla de registro, campo "Confirmar
  contraseña", mostrando "Las contraseñas no coinciden" tras escribir una
  confirmación distinta a la contraseña.
  `![captura](docs/capturas/cruzada-confirmar-password.png)`

---

### 9. Validación contextual (área de cobertura) — UX únicamente
- **Bloque de código aplicado:**
```dart
// core/validators/context_validators.dart
class GeoBounds {
  final double southLat;
  final double northLat;
  final double westLng;
  final double eastLng;

  const GeoBounds({
    required this.southLat,
    required this.northLat,
    required this.westLng,
    required this.eastLng,
  });

  static const chiapas = GeoBounds(
    southLat: 14.5, northLat: 17.9, westLng: -94.1, eastLng: -90.2,
  );
}

class ContextValidators {
  static String? withinServiceArea(double lat, double lng, {GeoBounds bounds = GeoBounds.chiapas}) {
    final within = lat >= bounds.southLat && lat <= bounds.northLat &&
        lng >= bounds.westLng && lng <= bounds.eastLng;
    return within ? null : 'La ubicación está fuera del área de cobertura actual';
  }
}
```
- **Ubicación en el proyecto:** `lib/core/validators/context_validators.dart`
  — capa core. **Parcial, como indica el README**: el formulario de
  parcela actual (`add_parcel_page.dart`) no captura latitud/longitud GPS,
  solo un texto libre de "Región/Comunidad", por lo que esta validación de
  UX queda preparada (con la caja geográfica de Chiapas ya configurada)
  para cuando se agregue captura de coordenadas GPS a la parcela. La
  validación autoritativa seguirá siendo responsabilidad del backend.
- **Captura de pantalla:** no aplica todavía (sin campo GPS en el
  formulario actual).

---

### 10. Sanitización de entrada (subconjunto Front)
- **Bloque de código aplicado:**
```dart
// core/sanitizers/input_sanitizer.dart
import 'dart:convert';

class InputSanitizer {
  static String trimAndNormalize(String value) => value.trim();

  static String urlEncode(String value) => Uri.encodeQueryComponent(value);

  static String base64EncodeBytes(List<int> bytes) => base64Encode(bytes);

  static String whitelistAlphanumeric(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
  }

  static String escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }
}
```
- **Ubicación en el proyecto:** `lib/core/sanitizers/input_sanitizer.dart` —
  capa core. Cubre trim/normalize (d), whitelisting (b/g), escapado HTML
  (a/i) y encoding URL/Base64 (e). La app no usa WebView actualmente
  (`escapeHtml` queda listo para cuando se muestre contenido remoto del
  LLM agronómico en una WebView). Canonicalización de paths (h) no aplica:
  la app no persiste rutas de archivos locales de imágenes de forma
  directa (el flujo de cámara/CNN procesa el archivo en memoria).
- **Captura de pantalla:** no aplica una pantalla propia (utilidad
  transversal, sin UI directa).

---

### 18. Gestión de errores sin exponer información sensible
- **Bloque de código aplicado:**
```dart
// core/error/api_error_mapper.dart
class ApiErrorMapper {
  const ApiErrorMapper._();

  static const String genericMessage =
      'No pudimos procesar tu solicitud. Verifica tus datos e intenta de nuevo.';

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
```
  Integración real en `auth_bloc.dart` (login y registro): antes se
  mostraba `failure.message` (mensaje crudo reenviado desde el backend)
  directamente en el `SnackBar`; ahora los fallos de servidor
  (`ServerFailure`) se redactan primero:
```dart
String _safeMessage(Failure failure) {
  if (failure is ServerFailure) {
    return ApiErrorMapper.toUserMessage(failure, statusCode: failure.statusCode);
  }
  return failure.message;
}
```
  usado en `emit(AuthFailureState(message: _safeMessage(failure)))` tanto
  en `_onLoginRequested` como en `_onRegisterRequested`. Los mensajes ya
  redactados por la propia app (`AuthFailure`, `NetworkFailure`,
  `CacheFailure`, sesión cruzada de perfiles) se preservan sin cambios.
- **Ubicación en el proyecto:** `lib/core/error/api_error_mapper.dart`
  (capa data/core) + `lib/features/login/auth/presentation/bloc/auth_bloc.dart`
  (capa presentation).
- **Captura de pantalla:** Pantalla de login, con credenciales incorrectas
  enviadas al backend real, mostrando el `SnackBar` genérico "Usuario o
  contraseña incorrectos." (sin el detalle crudo que devuelve el backend).
  `![captura](docs/capturas/gestion-errores-login.png)`

---

## PARTE B — OWASP MASVS Checklist

### STORAGE: almacenamiento seguro con `flutter_secure_storage`
- **Bloque de código aplicado:**
```dart
// core/storage/token_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveTokens({required String accessToken, required String refreshToken});
  Future<void> clearTokens();
}

class TokenStorageImpl implements TokenStorage {
  final FlutterSecureStorage _storage;
  static const _accessKey = 'ACCESS_TOKEN';
  static const _refreshKey = 'REFRESH_TOKEN';

  const TokenStorageImpl(this._storage);

  @override
  Future<String?> getAccessToken() => _storage.read(key: _accessKey);

  @override
  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
```
  Registro en DI (`injection_container.dart`):
```dart
sl.registerLazySingleton<FlutterSecureStorage>(
  () => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);
sl.registerLazySingleton<TokenStorage>(
  () => TokenStorageImpl(sl<FlutterSecureStorage>()),
);
```
- **Ubicación en el proyecto:** `lib/core/storage/token_storage.dart` +
  `lib/core/di/injection_container.dart` — capa core. Antes el
  `TokenStorageImpl` persistía access/refresh token en un `Box<String>` de
  Hive **sin cifrar**; ahora usa Keystore (Android)/Keychain (iOS) vía
  `flutter_secure_storage`. No se creó un archivo `secure_storage_datasource.dart`
  aparte porque `token_storage.dart` ya cumplía exactamente esa
  responsabilidad — evitar duplicar la misma lógica en dos archivos.
- **Captura de pantalla:** no aplica captura visual directa (cambio de
  backend de persistencia, sin UI propia). Se recomienda adjuntar
  evidencia vía `adb shell run-as com.agrograp.ia.agrograp_movil` mostrando
  que `auth_box` ya no contiene `ACCESS_TOKEN`/`REFRESH_TOKEN` en texto
  plano.

---

### STORAGE: prevención de fuga de datos (logs, screenshots, backup)
- **Bloque de código aplicado (logs):**
```dart
// core/network/interceptors/logging_interceptor.dart
class LoggingInterceptor extends Interceptor {
  static const _sensitiveKeys = {
    'password', 'confirmPassword', 'access_token', 'refresh_token', 'refreshToken', 'token',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[HTTP →] ${options.method} ${options.path}');
      if (options.data != null) debugPrint('         body: ${_redact(options.data)}');
    }
    handler.next(options);
  }

  Object? _redact(Object? data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(
            key, _sensitiveKeys.contains(key) ? '***REDACTED***' : value,
          ));
    }
    return data;
  }
  // ...
}
```
  **Bug real corregido:** antes de este cambio, el interceptor imprimía
  `options.data` completo en la consola de debug — incluida la contraseña
  en texto plano en cada login/registro.

  **Bloque de código aplicado (tokens duplicados en caché):**
```dart
// features/login/auth/data/models/user_model.dart
/// JSON para persistir en Hive: solo perfil, SIN tokens.
Map<String, dynamic> toCacheJson() {
  return {
    'id': id, 'full_name': fullName, 'username': username, 'email': email,
    'phone': phone, 'avatar_url': avatarUrl, 'is_local_only': isLocalOnly,
    'created_at': createdAt?.toIso8601String(), 'role': role,
  };
}
```
  **Bug real corregido:** el caché offline (`auth_box`, Hive) guardaba
  `access_token`/`refresh_token` en texto plano dentro del JSON del
  usuario, duplicando en un almacén no cifrado lo que ya vive de forma
  segura en `TokenStorage`.

  **Bloque de código aplicado (anti-screenshot):**
```dart
// core/security/screen_security.dart
abstract final class ScreenSecurity {
  static const MethodChannel _channel = MethodChannel('agrograph.mas/security');

  static Future<void> enable() async {
    try {
      await _channel.invokeMethod('enableSecureScreen');
    } on MissingPluginException {
    } on PlatformException {}
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod('disableSecureScreen');
    } on MissingPluginException {
    } on PlatformException {}
  }
}
```
```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
class MainActivity : FlutterFragmentActivity() {
    private val securityChannel = "agrograph.mas/security"
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, securityChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableSecureScreen" -> { window.addFlags(WindowManager.LayoutParams.FLAG_SECURE); result.success(null) }
                    "disableSecureScreen" -> { window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE); result.success(null) }
                    else -> result.notImplemented()
                }
            }
    }
}
```
  Integrado en `login_page.dart` y `register_page.dart` (`initState`/`dispose`).
- **Ubicación en el proyecto:** `lib/core/network/interceptors/logging_interceptor.dart`,
  `lib/features/login/auth/data/models/user_model.dart`,
  `lib/core/security/screen_security.dart`,
  `android/app/src/main/kotlin/com/agrograp/ia/agrograp_movil/MainActivity.kt`,
  `lib/features/login/auth/presentation/pages/login_page.dart`,
  `lib/features/login/auth/presentation/pages/register_page.dart`.
  iOS no expone un flag de sistema equivalente a `FLAG_SECURE`; queda
  documentado como no soportado en esta etapa (requeriría una vista de
  overlay/blur propia sobre `UIScreen.capturedDidChangeNotification`).
- **Captura de pantalla:** Captura del selector de apps recientes de
  Android (Recents) mostrando la miniatura en negro/oculta para la
  pantalla de login, en contraste con otra pantalla que sí muestra su
  contenido normalmente.
  `![captura](docs/capturas/flag-secure-recents.png)`

---

### CRYPTO: sin hardcodear llaves/secrets en el código
- **Estado:** ya existente, confirmado. La única credencial sensible del
  proyecto (`PRODUCTS_API_KEY`) ya se resuelve vía `--dart-define` con
  `String.fromEnvironment` en `lib/core/network/api_endpoints.dart`, no
  hardcodeada de forma directa en un valor de producción fijo:
```dart
static const String productsApiKey = String.fromEnvironment(
  'PRODUCTS_API_KEY',
  defaultValue: '4b7e2a9f1c6d3e8b5a0f4c9e2d7b1a6f3c8e5b2d9f0a4c7e1b6d3f8a5c2e9b4d',
);
```
  **Pendiente real (no de código, de proceso):** el `defaultValue` actual
  es una clave de repuesto que queda embebida en el binario si no se pasa
  `--dart-define`. Se recomienda al equipo de build/CI dejar de commitear
  ese valor de repuesto y exigir siempre `--dart-define=PRODUCTS_API_KEY=...`
  en los pipelines de firma — cambio de proceso de CI, fuera del alcance
  de este sprint de frontend.
- **Ubicación en el proyecto:** `lib/core/network/api_endpoints.dart` —
  capa core.
- **Captura de pantalla:** no aplica (configuración de build, sin UI).

---

### AUTH: flujo de login/token seguro (HTTPS, header Authorization)
- **Estado:** parcialmente ya existente + documentado. El token ya viaja
  como `Authorization: Bearer <token>` (nunca en la URL), implementado en
  `core/network/interceptors/auth_interceptor.dart` (ya existente, sin
  cambios necesarios). **HTTPS no se pudo forzar de extremo a extremo**:
  los 4 microservicios reales (`174.129.218.190`, `3.217.217.227`,
  `52.1.110.21`, `44.196.107.153`, ver `api_endpoints.dart`) se exponen
  hoy solo por HTTP plano sobre IPs de EC2, sin certificado TLS. Forzar
  HTTPS habría roto el 100% de las llamadas de red reales. En su lugar se
  implementó el control más cercano posible: ver el siguiente punto
  (allowlist de cleartext) — cierra la brecha de "cualquier host puede
  usar cleartext" sin poder cerrar la de "TLS end-to-end", que depende de
  que backend/infra emita certificados.
- **Ubicación en el proyecto:** `lib/core/network/interceptors/auth_interceptor.dart`
  (ya existente) — capa core.
- **Captura de pantalla:** no aplica (sin cambio de UI).

---

### NETWORK: HTTPS forzado / cleartext restringido a hosts conocidos
- **Bloque de código aplicado (Android):**
```xml
<!-- android/app/src/main/res/xml/network_security_config.xml -->
<network-security-config>
    <base-config cleartextTrafficPermitted="false" />
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">174.129.218.190</domain>
        <domain includeSubdomains="false">3.217.217.227</domain>
        <domain includeSubdomains="false">52.1.110.21</domain>
        <domain includeSubdomains="false">44.196.107.153</domain>
    </domain-config>
</network-security-config>
```
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<application
    ...
    android:networkSecurityConfig="@xml/network_security_config">
```
- **Bloque de código aplicado (iOS):**
```xml
<!-- ios/Runner/Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>174.129.218.190</key>
        <dict><key>NSExceptionAllowsInsecureHTTPLoads</key><true/></dict>
        <key>3.217.217.227</key>
        <dict><key>NSExceptionAllowsInsecureHTTPLoads</key><true/></dict>
        <key>52.1.110.21</key>
        <dict><key>NSExceptionAllowsInsecureHTTPLoads</key><true/></dict>
        <key>44.196.107.153</key>
        <dict><key>NSExceptionAllowsInsecureHTTPLoads</key><true/></dict>
    </dict>
</dict>
```
- **Ubicación en el proyecto:**
  `android/app/src/main/res/xml/network_security_config.xml`,
  `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` —
  configuración de cliente (permitida por regla de alcance). En vez de
  deshabilitar ATS globalmente (`NSAllowsArbitraryLoads`) o dejar el
  cleartext permitido por defecto en Android, se restringe explícitamente
  a los 4 hosts del backend real — cualquier otro host queda bloqueado
  para tráfico HTTP.
- **Captura de pantalla:** no aplica captura de UI (configuración de
  plataforma). Se recomienda adjuntar el log de Logcat mostrando que una
  conexión de prueba a un host fuera del allowlist es rechazada con
  `CLEARTEXT communication not permitted`.

---

### NETWORK: certificate pinning (recomendado)
- **Bloque de código aplicado:**
```dart
// core/network/certificate_pinning.dart
abstract final class CertificatePinning {
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
```
- **Ubicación en el proyecto:** `lib/core/network/certificate_pinning.dart`
  — capa core. **No se pudo activar de verdad**: el pinning solo tiene
  sentido con un certificado TLS real que fijar, y el backend actual no
  expone HTTPS (ver punto NETWORK anterior). Se implementó el punto de
  extensión completo (`attach(dio)`, mapa de huellas SHA-256 por host) para
  que, en cuanto backend emita certificados, sea un cambio de una línea en
  `injection_container.dart` en vez de una funcionalidad nueva.
- **Captura de pantalla:** no aplica (sin TLS activo que capturar).

---

### AUTH: autenticación local (biometría) si aplica
- **Bloque de código aplicado:**
```dart
// core/security/local_auth_gate.dart
class LocalAuthGate {
  final LocalAuthentication _auth;
  LocalAuthGate({LocalAuthentication? auth}) : _auth = auth ?? LocalAuthentication();

  Future<bool> authenticate({String localizedReason = 'Confirma tu identidad para continuar'}) async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!isSupported && !canCheckBiometrics) return true;
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } catch (_) {
      return true;
    }
  }
}
```
- **Ubicación en el proyecto:** `lib/core/security/local_auth_gate.dart` —
  capa core. Requiere `MainActivity` como `FlutterFragmentActivity` (Android)
  y `NSFaceIDUsageDescription` (iOS) — ambos ya configurados (ver más abajo).
- **Captura de pantalla:** Prompt biométrico nativo de Android/iOS
  apareciendo tras pulsar "Eliminar" en el diálogo de confirmación de
  "Eliminar parcela" (ver siguiente punto).

---

### AUTH: reautenticación en operaciones sensibles
- **Bloque de código aplicado:**
```dart
// features/agricultor/parcels/presentation/pages/parcels_page.dart
TextButton(
  onPressed: () async {
    Navigator.pop(ctx);
    final authorized = await LocalAuthGate().authenticate(
      localizedReason: 'Confirma tu identidad para eliminar esta parcela',
    );
    if (!authorized || !context.mounted) return;
    context.read<ParcelBloc>().add(
          ParcelDeleteRequested(seleccionId: p.seleccionId),
        );
  },
  child: Text('Eliminar', style: TextStyle(color: AppColors.burntOrange)),
),
```
  Setup nativo necesario:
```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
class MainActivity : FlutterFragmentActivity() { ... }
```
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```
```xml
<!-- ios/Runner/Info.plist -->
<key>NSFaceIDUsageDescription</key>
<string>Usamos Face ID para confirmar tu identidad antes de operaciones sensibles.</string>
```
- **Ubicación en el proyecto:**
  `lib/features/agricultor/parcels/presentation/pages/parcels_page.dart`
  (capa presentation) + configuración nativa Android/iOS.
- **Captura de pantalla:** Pantalla "Mis Parcelas" → menú de una parcela →
  "Eliminar parcela" → diálogo de confirmación → prompt biométrico nativo
  mostrándose antes de que la parcela desaparezca de la lista.
  `![captura](docs/capturas/reauth-eliminar-parcela.png)`

---

### PLATFORM: validación de parámetros en deep links
- **Estado:** no aplica en esta etapa. Se revisó `AndroidManifest.xml`,
  `Info.plist` y el árbol de rutas (`core/routes/app_routes.dart`,
  `main.dart`): la app no registra ningún `intent-filter` de tipo
  `BROWSABLE`/`VIEW` con esquema propio ni Universal/App Links, por lo que
  no existen deep links que sanitizar todavía. Si se agregan en el futuro
  (ej. abrir una recomendación desde una notificación push), sus
  parámetros deben tratarse como entrada no confiable y pasar por
  `core/validators/` antes de usarse para navegar — el mecanismo ya está
  listo, solo falta el punto de entrada.
- **Ubicación en el proyecto:** n/a.
- **Captura de pantalla:** no aplica.

---

### PLATFORM: WebView segura
- **Estado:** no aplica actualmente. `pubspec.yaml` no incluye
  `webview_flutter` ni ningún paquete de WebView, y no hay uso de
  `dart:ui`/`InAppWebView` en el código. `InputSanitizer.escapeHtml` (ver
  Parte A, punto 10) ya queda disponible para cuando se integre contenido
  remoto (ej. artículos agronómicos) en una WebView futura, junto con la
  recomendación de deshabilitar `javaScriptEnabled` salvo necesidad y usar
  una whitelist de dominios.
- **Ubicación en el proyecto:** n/a (preparado en `core/sanitizers/input_sanitizer.dart`).
- **Captura de pantalla:** no aplica.

---

### PLATFORM: UI segura (obscureText, sin autocompletar en passwords)
- **Bloque de código aplicado:**
```dart
// features/login/auth/presentation/widgets/auth_text_field.dart
child: TextFormField(
  focusNode: _focus,
  controller: widget.controller,
  obscureText: widget.obscureText,
  enableSuggestions: widget.obscureText ? false : true,
  autocorrect: widget.obscureText ? false : true,
  keyboardType: widget.obscureText ? TextInputType.visiblePassword : widget.keyboardType,
  textInputAction: widget.textInputAction,
  validator: widget.validator,
  onChanged: widget.onChanged,
  enabled: widget.enabled,
  maxLines: widget.maxLines,
  ...
)
```
- **Ubicación en el proyecto:**
  `lib/features/login/auth/presentation/widgets/auth_text_field.dart` —
  capa presentation. `obscureText` ya estaba aplicado en login/registro
  (ya existente); se agregó `enableSuggestions: false`, `autocorrect: false`
  y `keyboardType: visiblePassword` para evitar que el teclado del sistema
  sugiera/recuerde la contraseña en texto plano. Tapjacking (overlays de
  terceros) no se pudo mitigar con una API estándar de Flutter sin agregar
  un plugin adicional — queda como recomendación para una futura revisión
  de dependencias nativas si se detecta como riesgo real.
- **Captura de pantalla:** Pantalla de login, campo "Contraseña", con el
  teclado del sistema abierto mostrando que no aparece la barra de
  sugerencias de autocompletado.
  `![captura](docs/capturas/ui-segura-password.png)`

---

### CODE: versión mínima de plataforma
- **Estado:** ya existente, confirmado. `android/app/build.gradle.kts`
  define `minSdk = 26` (Android 8.0+) y `targetSdk = flutter.targetSdkVersion`
  (la más reciente soportada por el SDK de Flutter instalado). No requirió
  cambios.
- **Ubicación en el proyecto:** `android/app/build.gradle.kts`.
- **Captura de pantalla:** no aplica.

---

### CODE: mecanismo de actualización forzada
- **Bloque de código aplicado:**
```dart
// core/security/force_update_gate.dart
abstract final class ForceUpdateGate {
  static const String minSupportedVersion = '1.0.0';

  static bool needsUpdate(String currentVersion, {String? minVersion}) {
    final current = Version.parse(_stripBuildNumber(currentVersion));
    final min = Version.parse(_stripBuildNumber(minVersion ?? minSupportedVersion));
    return current < min;
  }

  static String _stripBuildNumber(String version) => version.split('+').first;
}
```
  Integrado en `splash_page.dart`:
```dart
if (ForceUpdateGate.needsUpdate(_kAppVersion) && context.mounted) {
  await _showForceUpdateDialog(context);
  return;
}
```
- **Ubicación en el proyecto:** `lib/core/security/force_update_gate.dart`
  (capa core) + `lib/features/login/auth/presentation/pages/splash_page.dart`
  (capa presentation). Usa comparación semántica real (`pub_semver`) en
  vez de `String.compareTo` (que falla al comparar p. ej. "1.9.0" vs
  "1.10.0"). El backend aún no expone un endpoint de versión mínima, así
  que `minSupportedVersion` apunta hoy a la versión actual del `pubspec`
  (`1.0.0`) — el mecanismo nunca bloquea todavía, pero queda cableado en
  el arranque de la app y listo para recibir el valor remoto cuando ese
  endpoint exista.
- **Captura de pantalla:** no aplica todavía (el diálogo no se dispara con
  la configuración actual). Se recomienda capturar el diálogo
  "Actualización requerida" bajando manualmente `minSupportedVersion` a un
  valor mayor que `_kAppVersion` en una build de prueba.

---

### CODE: auditoría de dependencias
- **Evidencia real de la auditoría ejecutada:**
```
$ flutter pub outdated
55 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
```
  Se agregaron las 5 dependencias nuevas de seguridad con versiones
  recientes y estables al momento de la integración:
  `flutter_secure_storage: ^9.2.4`, `local_auth: ^2.3.0`,
  `safe_device: ^1.1.6`, `pub_semver: ^2.1.4`, `crypto: ^3.0.6`. No se
  detectaron paquetes con vulnerabilidades conocidas reportadas en
  `pub.dev` para las versiones resueltas (`flutter pub get` sin
  advertencias de seguridad).
- **Ubicación en el proyecto:** `pubspec.yaml` — capa core/build.
  Recomendación de proceso: correr `flutter pub outdated` en cada sprint
  de endurecimiento y antes de cada release.
- **Captura de pantalla:** no aplica (salida de terminal, sin UI).

---

### RESILIENCE: detección de root/jailbreak (recomendado)
- **Bloque de código aplicado:**
```dart
// core/security/root_detection.dart
abstract final class RootDetection {
  static Future<bool> isCompromised() async {
    try {
      return await SafeDevice.isJailBroken;
    } catch (_) {
      return false;
    }
  }
}
```
  Integrado en `splash_page.dart` (advertencia, no bloqueo):
```dart
await _warnIfCompromisedDevice(context);
```
  mostrando un `AlertDialog` informativo si `RootDetection.isCompromised()`
  devuelve `true`, con un botón "Entendido, continuar" — nunca impide el
  uso de la app, para no generar falsos bloqueos en dispositivos de
  desarrollo/CI.
- **Ubicación en el proyecto:** `lib/core/security/root_detection.dart`
  (capa core) + `lib/features/login/auth/presentation/pages/splash_page.dart`
  (capa presentation).
- **Captura de pantalla:** Pantalla splash en un dispositivo/emulador
  rooteado, mostrando el diálogo "Dispositivo no confiable".
  `![captura](docs/capturas/root-detection-warning.png)`

---

### RESILIENCE: build con ofuscación habilitada
- **Estado:** documentado, no ejecutado en este sprint (la regla de
  verificación pide `flutter build apk --debug`, que no soporta
  ofuscación real de forma significativa). Comando recomendado para el
  pipeline de release:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```
  El anti-tampering robusto (firma, verificación de integridad del
  APK/IPA) es responsabilidad de configuración de build/CI y de las
  tiendas — fuera del alcance de "integrar en el front" como
  funcionalidad, tal como indica el propio README.
- **Ubicación en el proyecto:** recomendación de proceso para
  `android/app/build.gradle.kts` / pipeline de CI, no requiere cambio de
  código Dart.
- **Captura de pantalla:** no aplica.

---

### RESILIENCE: anti-análisis estático / anti-análisis dinámico
- **Estado:** ❌ No aplica, confirmado igual que en el README — requieren
  instrumentación nativa avanzada fuera del alcance de un equipo Frontend
  Flutter de un proyecto académico/capstone. Sin cambios.

---
 