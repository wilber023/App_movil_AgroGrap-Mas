# README — Validación de Entradas y Seguridad Móvil (Frontend Flutter)
### Proyecto: AgroGraph — Equipo Frontend (Flutter Mobile)

Este documento reúne **únicamente** lo que el equipo de Frontend (Flutter) debe integrar en la app móvil, extraído de dos fuentes:

- **Parte A** → `SI - C3 - Validación de entradas de datos.pdf`
- **Parte B** → `OWASP_MAS_Checklist.xlsx` (OWASP MASVS v2.0.0 / MASTG v1.7.0)

Cada punto incluye: descripción breve, **si aplica o no al Frontend**, en qué parte de la arquitectura Clean Architecture del proyecto debe ir (`domain/`, `data/`, `presentation/`, `core/`), y un bloque de código **solo cuando el punto lo amerita**. Al final hay una **tabla de cumplimiento** para que el equipo marque lo que ya está implementado y reporte lo que falta.

> Convención de capas usada (según arquitectura actual de AgroGraph):
> - `core/validators/` → funciones puras de validación reutilizables.
> - `core/network/ApiClient` → configuración del cliente HTTP compartido.
> - `domain/` → reglas de negocio y value objects.
> - `data/` → mapeo e implementación de repos/DTOs.
> - `presentation/` → formularios, widgets, `FormFieldValidator`, controllers/blocs.

---

## PARTE A — Validación y Sanitización de Entradas
**Fuente:** Documento de validación de entradas de datos

### Resumen rápido

| # | Tipo de validación | ¿Aplica al Front? |
|---|---|---|
| 1 | Validación de formato | ✅ Sí |
| 2 | Validación de longitud | ✅ Sí |
| 3 | Validación de rango | ✅ Sí |
| 4 | Validación de contenido | ✅ Sí |
| 5 | Validación con regex | ✅ Sí |
| 6 | Validación de tipo de dato | ✅ Sí |
| 7 | Validación de patrones específicos (email, tarjeta, contraseña) | ✅ Sí |
| 8 | Validación cruzada | ✅ Sí |
| 9 | Validación contextual | ⚠️ Parcial |
| 10 | Sanitización de entrada (escapado, filtrado, limpieza, codificación) | ✅ Sí (subconjunto) |
| 11 | Validación de autenticidad (tokens) | ❌ No (backend) |
| 12 | Validación de consistencia (BD) | ❌ No (backend) |
| 13 | Validación de integridad de transmisión | ❌ No (backend/infra) |
| 14 | Validación de permisos | ❌ No (backend, el front solo oculta UI) |
| 15 | Validación de lógica de negocio (ej. inventario) | ⚠️ Parcial (solo UX, no como control de seguridad) |
| 16 | Uso de librerías/frameworks de validación | ✅ Sí |
| 17 | Educación del equipo | ⚠️ Proceso, no código |
| 18 | Gestión de errores adecuada | ✅ Sí |

---

### 1. Validación de formato
**Descripción:** Verificar que el dato cumpla un formato esperado (correo, teléfono, fecha) antes de enviarlo al backend.
**Dónde va:** `core/validators/format_validators.dart`, consumido por `FormFieldValidator` en `presentation/`.

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

---

### 2. Validación de longitud
**Descripción:** Evitar campos demasiado cortos o largos (nombres, descripciones de diagnóstico, comentarios).
**Dónde va:** `core/validators/length_validators.dart`.

```dart
class LengthValidators {
  static String? range(String? value, {required int min, required int max, String field = 'Campo'}) {
    if (value == null) return '$field es obligatorio';
    if (value.length < min) return '$field debe tener al menos $min caracteres';
    if (value.length > max) return '$field no debe exceder $max caracteres';
    return null;
  }
}
```

---

### 3. Validación de rango
**Descripción:** Para datos numéricos, por ejemplo edad del productor, área de parcela en hectáreas, humedad/temperatura reportada manualmente.
**Dónde va:** `core/validators/range_validators.dart`.

```dart
class RangeValidators {
  static String? numericRange(num? value, {required num min, required num max, String field = 'Valor'}) {
    if (value == null) return '$field es obligatorio';
    if (value < min || value > max) return '$field debe estar entre $min y $max';
    return null;
  }
}
```

---

### 4. Validación de contenido
**Descripción:** Rechazar caracteres no permitidos/peligrosos en campos de texto libre (nombres, notas de diagnóstico).
**Dónde va:** `core/validators/content_validators.dart`.

```dart
class ContentValidators {
  // Solo letras (incluye acentos/ñ), espacios y guiones — útil para nombres de productor
  static String? safeName(String? value) {
    if (value == null || value.isEmpty) return 'Este campo es obligatorio';
    final regex = RegExp(r"^[a-zA-ZÀ-ÿñÑ\s\-]+$");
    return regex.hasMatch(value) ? null : 'No se permiten caracteres especiales ni números';
  }
}
```

---

### 5. Validación con expresiones regulares (regex)
**Descripción:** Motor genérico reutilizable para cualquier patrón (usado por los validadores anteriores). Se lista aparte porque el documento lo señala como categoría propia.
**Dónde va:** `core/validators/regex_validator.dart`.

```dart
class RegexValidator {
  static String? matches(String? value, RegExp pattern, {String errorMessage = 'Formato inválido'}) {
    if (value == null || value.isEmpty) return 'Este campo es obligatorio';
    return pattern.hasMatch(value) ? null : errorMessage;
  }
}
```

---

### 6. Validación de tipo de dato
**Descripción:** Verificar que el dato ingresado corresponda al tipo esperado (número donde se espera número, fecha, etc.) antes de construir el DTO que se envía al backend.
**Dónde va:** `domain/` como *Value Objects* (fuerzan el tipo en su constructor) y en `presentation/` al parsear inputs de `TextField` (que siempre entregan `String`).

```dart
class Hectareas {
  final double value;
  Hectareas(String raw) : value = _parse(raw);

  static double _parse(String raw) {
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null) throw FormatException('Hectáreas debe ser numérico');
    return parsed;
  }
}
```

---

### 7. Validación de patrones y reglas específicas
**Descripción:** Reglas concretas para campos particulares: correo (formato+dominio), número de tarjeta (Luhn) y fortaleza de contraseña.
**Dónde va:** `core/validators/pattern_validators.dart`.

```dart
class PatternValidators {
  // Algoritmo de Luhn para validar número de tarjeta (si AgroGraph maneja pagos B2B/B2G)
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

  // Fortaleza de contraseña: min. 8 caracteres, mayúscula, minúscula, número y símbolo
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

---

### 8. Validación cruzada
**Descripción:** Comparar campos entre sí (ej. "fecha de siembra" no puede ser posterior a "fecha de cosecha"; "confirmar contraseña" debe coincidir con "contraseña").
**Dónde va:** `presentation/` a nivel de formulario (no en un solo `FormFieldValidator`, porque necesita el valor de dos campos), o como método de validación del Bloc/Controller antes de invocar el `UseCase`.

```dart
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

---

### 9. Validación contextual — ⚠️ Aplica parcialmente
**Descripción del documento:** Verificar que el dato sea válido en su contexto de uso (ej. dirección de envío dentro del área de cobertura).
**Por qué es parcial en el front:** el front puede hacer una validación *optimista* (ej. verificar que las coordenadas GPS estén dentro del rango geográfico de Chiapas/zona agrícola configurada) para mejorar UX, pero **la validación autoritativa** (si la parcela realmente pertenece a una región con cobertura de servicio) depende de datos del backend (microservicio de zonas/epidemiología) y no debe confiarse solo en el cliente.

```dart
// Validación optimista de UX — no reemplaza la verificación del backend
class ContextValidators {
  static String? withinServiceArea(double lat, double lng, {required LatLngBounds bounds}) {
    final within = lat >= bounds.southLat && lat <= bounds.northLat &&
                    lng >= bounds.westLng && lng <= bounds.eastLng;
    return within ? null : 'La ubicación está fuera del área de cobertura actual';
  }
}
```

---

### 10. Sanitización de entrada (subconjunto aplicable al Front)
El documento lista 10 técnicas de sanitización (a–j). No todas aplican al cliente Flutter (varias son responsabilidad exclusiva del backend, como el escapado SQL). Abajo se separa qué corresponde al front:

| Técnica del documento | ¿Aplica al Front? | Razón |
|---|---|---|
| a. Escapado de caracteres (HTML/JS) | ✅ Sí | Si el front renderiza HTML dinámico (ej. WebView con contenido remoto) debe escapar antes de mostrarlo. |
| a. SQL Escaping | ❌ No | El front nunca construye SQL; esto es responsabilidad exclusiva del backend/ORM. |
| b. Filtrado (whitelisting/blacklisting) | ✅ Sí | Restringir caracteres permitidos en inputs (ver punto 4). |
| c. Validación de tipo de datos / estructuras (JSON) | ✅ Sí | Validar que la respuesta/petición JSON tenga el shape esperado antes de parsear (DTOs con `fromJson` defensivo). |
| d. Limpieza (trim, normalize) | ✅ Sí | Aplicar a todo input de texto antes de enviarlo. |
| e. Codificación (Base64, URL encoding) | ✅ Sí | URL-encode de query params; Base64 si se envían imágenes/binarios del diagnóstico CNN. |
| f. Librerías seguras (ORM, ESAPI) | ❌ No (backend) | ORMs y ESAPI son de servidor. El equivalente en front es usar el `ApiClient`/`dio` en vez de construir requests manuales. |
| g. Reemplazo de caracteres | ✅ Sí | Parte del filtrado de contenido (punto 4). |
| h. Canonicalización (paths, mayúsc/minúsc) | ⚠️ Parcial | Aplica si el front maneja rutas de archivos locales (ej. imágenes tomadas con la cámara) — normalizar rutas antes de guardarlas. |
| i. Escape de salida contextual | ✅ Sí | Al mostrar datos generados por el LLM agronómico o por otros usuarios, escapar antes de renderizar en UI/WebView. |
| j. Revisiones y auditorías de código | ⚠️ Proceso | No es código, es práctica de equipo (lint estático con `flutter analyze`, revisiones de PR). |

```dart
// core/sanitizers/input_sanitizer.dart
class InputSanitizer {
  static String trimAndNormalize(String value) => value.trim();

  // Whitelisting simple para usernames
  static String whitelistAlphanumeric(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
  }

  // Escapado antes de mostrar contenido dinámico en un WebView/HTML
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

---

### 11–14. Autenticidad de tokens, consistencia BD, integridad de transmisión, permisos — ❌ No aplican al Front
**Por qué no aplican:** estas cuatro validaciones dependen de estado y lógica que **solo el servidor puede garantizar de forma confiable** (un token puede ser copiado/modificado en el dispositivo, las relaciones entre tablas viven en la BD, la integridad de transmisión depende de TLS/firma en servidor, y los permisos reales deben verificarse siempre server-side). El front puede reflejar el resultado (ej. ocultar botones sin permiso) **solo por UX**, nunca como control de seguridad real.

---

### 15. Validación de lógica de negocio — ⚠️ Aplica parcialmente
**Descripción:** Ej. no permitir pedidos que excedan inventario. En AgroGraph, el equivalente sería no permitir reportar un diagnóstico sin foto, o no permitir avanzar el flujo Aprendiz→recomendación sin completar pasos previos.
**Dónde va:** `domain/usecases/` — el UseCase puede rechazar la operación antes de llamar al repositorio, pero **la validación autoritativa de negocio (ej. cuotas, inventario real) siempre debe repetirse en backend**.

---

### 16. Uso de librerías/frameworks de validación
**Descripción:** Usar librerías mantenidas en vez de reinventar validadores.
**Recomendado para Flutter:** `formz`, `reactive_forms` o validadores nativos de `Form`/`TextFormField` con `validator:`. Mantener las funciones anteriores centralizadas en `core/validators/` para que cualquier librería las consuma.

---

### 18. Gestión de errores adecuada
**Descripción:** Los errores de validación no deben revelar información sensible (ej. no decir "el usuario no existe" vs "la contraseña es incorrecta"; no mostrar stack traces del backend).
**Dónde va:** `data/` al mapear errores de la API a mensajes genéricos antes de que lleguen a `presentation/`.

```dart
class ApiErrorMapper {
  static String toUserMessage(Object error) {
    // Nunca mostrar el mensaje crudo del backend ni stack traces al usuario
    return 'No pudimos procesar tu solicitud. Verifica tus datos e intenta de nuevo.';
  }
}
```

---

## PARTE B — OWASP MASVS Checklist
**Fuente:** `OWASP_MAS_Checklist.xlsx` (MASVS v2.0.0)

> Nota metodológica: el checklist original organiza los requisitos en 7 categorías (STORAGE, CRYPTO, AUTH, NETWORK, PLATFORM, CODE, RESILIENCE), cada una con enunciados de nivel de control aplicables a Android/iOS. Abajo se presentan **solo los enunciados con contenido textual disponible en el archivo**, indicando cuáles son responsabilidad del Frontend Flutter.

### MASVS-STORAGE (Almacenamiento)

| Requisito | ¿Aplica al Front? | Dónde / Cómo |
|---|---|---|
| El app almacena de forma segura los datos sensibles. | ✅ Sí | Usar `flutter_secure_storage` (Keychain/Keystore) para tokens y credenciales — **nunca** `SharedPreferences` en texto plano. Capa: `data/local/secure_storage_datasource.dart`. |
| El app previene la fuga de datos sensibles. | ✅ Sí | No hacer `print()`/log de tokens o datos del productor; deshabilitar capturas de pantalla en pantallas sensibles (`FlutterWindowManager.addFlags(FLAG_SECURE)` en Android); excluir campos sensibles del backup automático. |

```dart
// data/local/secure_storage_datasource.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageDataSource {
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) => _storage.write(key: 'auth_token', value: token);
  Future<String?> getToken() => _storage.read(key: 'auth_token');
  Future<void> clear() => _storage.deleteAll();
}
```

---

### MASVS-CRYPTO (Criptografía) — ⚠️ Aplica parcialmente

| Requisito | ¿Aplica al Front? | Razón |
|---|---|---|
| El app emplea criptografía fuerte y actualizada según buenas prácticas. | ⚠️ Parcial | El grueso de la criptografía (cifrado de datos en tránsito/reposo en servidor, hashing de contraseñas) es responsabilidad del backend. El front **solo** debe usar librerías estándar (`cryptography`, `encrypt`) si necesita cifrar algo localmente (ej. caché offline de diagnósticos) — nunca implementar cifrado propio. |
| El app realiza gestión de llaves según buenas prácticas. | ⚠️ Parcial | El front no gestiona llaves de servidor. Solo debe evitar hardcodear API keys/secrets en el código fuente (usar variables de entorno / `--dart-define` en build) y almacenar cualquier llave local en el Keystore/Keychain vía `flutter_secure_storage`. |

---

### MASVS-AUTH (Autenticación y Autorización)

| Requisito | ¿Aplica al Front? | Dónde / Cómo |
|---|---|---|
| El app usa protocolos de autenticación/autorización seguros y sigue buenas prácticas. | ✅ Sí (lado cliente) | Implementar el flujo (login, refresh token, logout) contra el microservicio de usuarios, usando siempre HTTPS y enviando el token vía header `Authorization: Bearer`, nunca en la URL. Capa: `data/repositories/auth_repository_impl.dart`. |
| El app realiza autenticación local de forma segura según buenas prácticas de la plataforma. | ✅ Sí | Si se implementa biometría/PIN para reabrir la app, usar `local_auth` (Face ID/Touch ID/huella) en vez de un PIN propio guardado en texto plano. |
| El app asegura operaciones sensibles con autenticación adicional. | ✅ Sí | Para acciones críticas (ej. eliminar diagnóstico, acceder al panel admin desde el móvil) pedir reautenticación o confirmación biométrica antes de invocar el `UseCase`. |

```dart
// presentation/auth/local_auth_gate.dart
import 'package:local_auth/local_auth.dart';

class LocalAuthGate {
  final _auth = LocalAuthentication();

  Future<bool> authenticate() => _auth.authenticate(
        localizedReason: 'Confirma tu identidad para continuar',
        options: const AuthenticationOptions(biometricOnly: false),
      );
}
```

---

### MASVS-NETWORK (Comunicación de Red)

| Requisito | ¿Aplica al Front? | Dónde / Cómo |
|---|---|---|
| El app asegura todo el tráfico de red según las mejores prácticas actuales. | ✅ Sí | Forzar HTTPS en el `ApiClient` (base URL con `https://`), deshabilitar tráfico en texto plano (`android:usesCleartextTraffic="false"` en `AndroidManifest.xml`, `NSAllowsArbitraryLoads=false` en iOS `Info.plist`). |
| El app implementa *certificate/identity pinning* para los endpoints propios. | ⚠️ Recomendado | Opcional pero recomendado dado que AgroGraph maneja datos económicos y agronómicos sensibles: usar `dio` con un `HttpClientAdapter` que valide el certificado del servidor EC2. |

```dart
// core/network/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient() : dio = Dio(BaseOptions(
          baseUrl: 'https://api.agrograph.com', // nunca http://
          connectTimeout: const Duration(seconds: 10),
        ));
}
```

---

### MASVS-PLATFORM (Interacción con la Plataforma)

| Requisito | ¿Aplica al Front? | Dónde / Cómo |
|---|---|---|
| El app usa mecanismos de IPC de forma segura. | ⚠️ Parcial | Si AgroGraph usa *deep links* (ej. abrir una recomendación desde una notificación), validar y sanitizar todos los parámetros del enlace antes de usarlos — tratarlos como entrada no confiable. |
| El app usa WebViews de forma segura. | ⚠️ Aplica solo si se usa WebView | Si se muestra contenido remoto (ej. artículos agronómicos), deshabilitar `javaScriptEnabled` salvo que sea estrictamente necesario, no cargar URLs arbitrarias sin whitelist de dominios, y escapar cualquier dato inyectado (ver Parte A, punto 10.i). |
| El app usa la interfaz de usuario de forma segura. | ✅ Sí | Usar `obscureText: true` en campos de contraseña, deshabilitar autocompletado/keyboard cache en campos sensibles, prevenir *tapjacking* evitando overlays de terceros sobre pantallas de login/pago. |

```dart
// presentation/widgets/secure_password_field.dart
TextFormField(
  obscureText: true,
  enableSuggestions: false,
  autocorrect: false,
  keyboardType: TextInputType.visiblePassword,
  validator: PatternValidators.strongPassword,
)
```

---

### MASVS-CODE (Calidad del Código)

| Requisito | ¿Aplica al Front? | Dónde / Cómo |
|---|---|---|
| El app requiere una versión actualizada de la plataforma. | ⚠️ Parcial | Configurar `minSdkVersion` (Android) / `Deployment Target` (iOS) adecuados; es más config de build que código de feature. |
| El app tiene un mecanismo para forzar actualizaciones. | ✅ Sí | Al iniciar, comparar la versión instalada contra una versión mínima devuelta por el backend y bloquear el uso con un diálogo si está desactualizada. |
| El app solo usa componentes de software sin vulnerabilidades conocidas. | ✅ Sí | Ejecutar `flutter pub outdated` / auditar `pubspec.yaml` periódicamente; fijar versiones y actualizar dependencias con CVEs conocidos. |
| **El app valida y sanitiza todas las entradas no confiables.** | ✅ Sí — **núcleo de este documento** | Ver íntegramente la **Parte A** de este README. |

```dart
// presentation/startup/force_update_gate.dart
class ForceUpdateGate {
  static bool needsUpdate(String currentVersion, String minVersion) {
    // Comparación semántica simple (usar package:pub_semver en producción)
    return currentVersion.compareTo(minVersion) < 0;
  }
}
```

---

### MASVS-RESILIENCE (Resiliencia ante Ingeniería Inversa y Manipulación)

| Requisito | ¿Aplica al Front? | Razón |
|---|---|---|
| El app valida la integridad de la plataforma (detección root/jailbreak). | ✅ Sí (recomendado) | Dado que AgroGraph maneja datos económicos/agronómicos, se recomienda usar `flutter_jailbreak_detection` o `safe_device` para advertir/restringir uso en dispositivos rooteados/con jailbreak. |
| El app implementa mecanismos anti-tampering. | ⚠️ Parcial | El front puede habilitar ofuscación al compilar (`flutter build apk --obfuscate --split-debug-info=<dir>`), pero el anti-tampering robusto (firma, verificación de integridad del APK/IPA) es responsabilidad de configuración de build/CI y de las tiendas, no lógica de feature. |
| El app implementa mecanismos anti-análisis estático. | ❌ No aplica como feature de front | Se logra mediante ofuscación de build (ver punto anterior) y configuración de CI/CD, no mediante código de pantallas o validadores. Fuera del alcance de "integrar en el front" como funcionalidad. |
| El app implementa técnicas anti-análisis dinámico (anti-debugging/anti-Frida). | ❌ No aplica en esta etapa | Requiere instrumentación nativa avanzada (Android/iOS) fuera del alcance típico de un equipo Frontend Flutter de un proyecto académico/capstone; se recomienda evaluarlo solo si el nivel de riesgo del producto lo justifica más adelante. |

---

## REPORTE DE CUMPLIMIENTO (para completar por el equipo Front)

Marcar `[x]` lo implementado y `[ ]` lo pendiente. Si un punto no aplica, dejar la razón ya documentada arriba y no marcarlo como pendiente.

### Parte A — Validación de entradas
- [ ] Validación de formato (email, teléfono, fecha)
- [ ] Validación de longitud
- [ ] Validación de rango
- [ ] Validación de contenido (whitelisting de caracteres)
- [ ] Validador regex genérico
- [ ] Validación de tipo (Value Objects en domain)
- [ ] Patrones específicos (Luhn, fortaleza de contraseña)
- [ ] Validación cruzada (fechas, confirmación de contraseña)
- [ ] Validación contextual (área de cobertura) — UX únicamente
- [ ] Sanitización: trim/normalize
- [ ] Sanitización: whitelisting de caracteres
- [ ] Sanitización: escapado HTML antes de render dinámico
- [ ] Sanitización: encoding (URL/Base64) donde aplique
- [ ] Gestión de errores sin exponer info sensible

### Parte B — OWASP MASVS
- [ ] STORAGE: almacenamiento seguro con `flutter_secure_storage`
- [ ] STORAGE: prevención de fuga (logs, screenshots, backup)
- [ ] CRYPTO: sin hardcodear llaves/secrets en el código
- [ ] AUTH: flujo de login/token seguro (HTTPS, header Authorization)
- [ ] AUTH: autenticación local (biometría/PIN) si aplica
- [ ] AUTH: reautenticación en operaciones sensibles
- [ ] NETWORK: HTTPS forzado, cleartext deshabilitado
- [ ] NETWORK: certificate pinning (recomendado)
- [ ] PLATFORM: validación de parámetros en deep links
- [ ] PLATFORM: WebView segura (si se usa)
- [ ] PLATFORM: UI segura (obscureText, sin autocompletar en passwords)
- [ ] CODE: mecanismo de actualización forzada
- [ ] CODE: auditoría de dependencias
- [ ] RESILIENCE: detección de root/jailbreak (recomendado)
- [ ] RESILIENCE: build con ofuscación habilitada

---

## Notas finales
- Los puntos marcados como **❌ No aplica** están fuera del alcance del Frontend porque dependen de infraestructura de servidor, base de datos, o de configuración de build/CI que no corresponde a lógica de pantallas/formularios — no porque se estén ignorando.
- Todo lo marcado como **⚠️ Parcial/Recomendado** debe discutirse con el equipo de backend/arquitectura para decidir si se prioriza en este sprint o en una iteración posterior de endurecimiento de seguridad.
- Este README debe mantenerse versionado junto al código (`docs/README_Frontend_Validacion_Seguridad.md`) y actualizarse cada vez que se audite el checklist OWASP MASVS de nuevo.
