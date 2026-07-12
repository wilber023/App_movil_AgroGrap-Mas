# AgroGraph — Guía de integración del API de pagos

Guía para el equipo frontend. Cubre todos los endpoints, el flujo completo de suscripción con PayPal, manejo de errores y detector de tipo de tarjeta.

---

## Índice

1. [Base URL](#base-url)
2. [Autenticación](#autenticación)
3. [Planes y precios](#planes-y-precios)
4. [Endpoints](#endpoints)
5. [Flujo completo de suscripción](#flujo-completo-de-suscripción)
6. [Código Flutter listo para usar](#código-flutter-listo-para-usar)
7. [Detector de tipo de tarjeta](#detector-de-tipo-de-tarjeta)
8. [Manejo de errores](#manejo-de-errores)
9. [Checklist de integración](#checklist-de-integración)

---

## Base URL

```
http://44.196.107.153:3000/api/payments
```

> **Ambiente actual:** PayPal Sandbox. Para pruebas de pago usa las cuentas sandbox de [developer.paypal.com](https://developer.paypal.com/dashboard/accounts). Las tarjetas reales no funcionan en sandbox.

Verificar que el servidor está activo:

```
GET http://44.196.107.153:3000/health
```

```json
{ "status": "ok", "db": "connected" }
```

---

## Autenticación

Todos los endpoints marcados con 🔒 requieren un JWT en el header `Authorization`.

```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

- El JWT lo emite el microservicio de autenticación de tu app con el mismo `JWT_SECRET`.
- **Nunca** lo envíes en la URL ni en el body.
- Si el token está vencido o es inválido el servidor responde `401`.
- Si el plan del usuario expiró, el servidor lo degrada a `free` automáticamente — no lo manejes en el frontend.

---

## Planes y precios

AgroGraph tiene exactamente dos planes. El valor de `plan` es el que se envía al endpoint `/subscribe`.

| Plan | Precio | Valor `plan` |
|------|--------|--------------|
| Premium | **$9.99 / mes** | `"monthly"` |
| Premium Annual | **$89.99 / año** | `"yearly"` |

---

## Endpoints

### `GET /health` — público

Verifica que el servidor y la base de datos estén funcionando.

**Request**
```
GET http://44.196.107.153:3000/health
```

**Response `200`**
```json
{ "status": "ok", "db": "connected" }
```

---

### `POST /subscribe` 🔒

Crea una suscripción en PayPal. Devuelve la URL donde el usuario aprueba el pago.

**Request**
```http
POST http://44.196.107.153:3000/api/payments/subscribe
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "plan": "monthly",
  "return_url": "agrograph://payment/success",
  "cancel_url": "agrograph://payment/cancel"
}
```

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `plan` | string | No | `"monthly"` o `"yearly"`. Default: `"monthly"` |
| `return_url` | string | No | Deep link al que PayPal redirige al aprobar |
| `cancel_url` | string | No | Deep link al que PayPal redirige al cancelar |

**Response `201`**
```json
{
  "subscriptionId": "I-BW452GLLEP1G",
  "approveUrl": "https://www.paypal.com/webapps/billing/subscriptions/...token=...",
  "status": "APPROVAL_PENDING"
}
```

> **Qué hacer con `approveUrl`:** ábrelo con `url_launcher` en `LaunchMode.externalApplication`. **No uses WebView.** PayPal gestiona todo el proceso de pago. Cuando el usuario termina, regresa a tu app y tú llamas a `GET /subscription` para confirmar.

---

### `GET /subscription` 🔒

Consulta el estado actual de la suscripción. Siempre verifica contra PayPal en tiempo real.

**Request**
```http
GET http://44.196.107.153:3000/api/payments/subscription
Authorization: Bearer <jwt_token>
```

**Response `200`**
```json
{
  "id": "I-BW452GLLEP1G",
  "status": "ACTIVE",
  "planId": "P-5ML4271244454362WXNWU5NQ",
  "planType": "monthly",
  "nextBillingTime": "2026-08-11T10:00:00Z",
  "lastPayment": {
    "amount": "9.99",
    "currency": "USD",
    "time": "2026-07-11T10:00:00Z"
  },
  "subscriber": {
    "email": "usuario@email.com",
    "payerId": "PAYERID123"
  }
}
```

**Response `404`** — el usuario no tiene suscripción activa.

**Estados posibles de `status`**

| `status` | `planType` | Qué muestra la UI |
|----------|------------|-------------------|
| `ACTIVE` | `monthly` / `yearly` | ✅ Plan Premium activo |
| `APPROVAL_PENDING` | `free` | ⏳ Esperando aprobación en PayPal |
| `CANCELLED` | `free` | Mostrar pantalla de planes |
| `SUSPENDED` | `free` | Plan pausado por PayPal |
| `404` | — | Sin suscripción — mostrar planes |

---

### `POST /cancel` 🔒

Cancela la suscripción activa. Muestra siempre un diálogo de confirmación antes de llamar.

**Request**
```http
POST http://44.196.107.153:3000/api/payments/cancel
Authorization: Bearer <jwt_token>
Content-Type: application/json

{}
```

**Response `200`**
```json
{ "message": "Subscription cancelled successfully" }
```

---

### `POST /webhook` — solo PayPal

No llamar desde la app. PayPal lo usa internamente para notificar eventos. Siempre responde `200`.

---

## Flujo completo de suscripción

```
App                         Servidor                    PayPal
 │                              │                          │
 │── POST /subscribe ──────────▶│                          │
 │   Authorization: Bearer jwt  │── POST /v1/billing/ ───▶│
 │                              │   subscriptions          │
 │                              │◀── { id, approveUrl } ──│
 │◀── { subscriptionId,         │                          │
 │     approveUrl,              │                          │
 │     status: APPROVAL_PENDING}│                          │
 │                              │                          │
 │── Abre approveUrl ────────────────────────────────────▶│
 │   url_launcher (browser)     │   Usuario aprueba/paga   │
 │                              │                          │
 │                              │◀── Webhook ─────────────│
 │                              │ BILLING.SUBSCRIPTION.    │
 │                              │ ACTIVATED                │
 │                              │ PAYMENT.SALE.COMPLETED   │
 │                              │   (actualiza BD)         │
 │                              │                          │
 │◀── AppLifecycleState.resumed │                          │
 │    (usuario regresa a la app)│                          │
 │                              │                          │
 │── GET /subscription ────────▶│                          │
 │◀── { status: "ACTIVE" } ─────│                          │
 │                              │                          │
 │   Muestra plan activo ✓      │                          │
```

### Punto crítico: tiempo entre retorno del browser y webhook

PayPal puede tardar entre 1 y 10 segundos en enviar el webhook después de que el usuario aprueba. Por eso hay que hacer **polling** al volver a la app:

```
Al detectar AppLifecycleState.resumed:
  Repetir hasta 5 veces con 3 segundos de espera:
    GET /subscription
    Si status == "ACTIVE" → mostrar éxito y parar
  Si no se activó en 15 segundos → mostrar mensaje "Verificando tu pago..."
```

---

## Código Flutter listo para usar

### Servicio de pagos

```dart
// lib/services/payment_service.dart
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

const _base = 'http://44.196.107.153:3000/api/payments';

Map<String, String> _headers(String jwt) => {
  'Authorization': 'Bearer $jwt',
  'Content-Type': 'application/json',
};

// Iniciar suscripción
Future<Map<String, dynamic>> subscribe(String jwt, String plan) async {
  final res = await http.post(
    Uri.parse('$_base/subscribe'),
    headers: _headers(jwt),
    body: jsonEncode({
      'plan': plan,
      'return_url': 'agrograph://payment/success',
      'cancel_url':  'agrograph://payment/cancel',
    }),
  );
  if (res.statusCode == 201) return jsonDecode(res.body);
  final error = jsonDecode(res.body)['error'] ?? 'Error desconocido';
  throw Exception(error);
}

// Abrir aprobación en browser externo
Future<void> openApprovalPage(String approveUrl) async {
  final uri = Uri.parse(approveUrl);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('No se pudo abrir el navegador');
  }
}

// Consultar estado
Future<Map<String, dynamic>?> getSubscription(String jwt) async {
  final res = await http.get(
    Uri.parse('$_base/subscription'),
    headers: _headers(jwt),
  );
  if (res.statusCode == 200) return jsonDecode(res.body);
  if (res.statusCode == 404) return null; // sin suscripción, no es error
  throw Exception('Error al consultar suscripción');
}

// Polling al volver del browser (hasta 5 intentos)
Future<Map<String, dynamic>?> pollUntilActive(String jwt) async {
  for (int i = 0; i < 5; i++) {
    await Future.delayed(const Duration(seconds: 3));
    final sub = await getSubscription(jwt);
    if (sub?['status'] == 'ACTIVE') return sub;
  }
  return null;
}

// Cancelar suscripción
Future<void> cancelSubscription(String jwt) async {
  final res = await http.post(
    Uri.parse('$_base/cancel'),
    headers: _headers(jwt),
    body: '{}',
  );
  if (res.statusCode != 200) {
    final error = jsonDecode(res.body)['error'] ?? 'Error al cancelar';
    throw Exception(error);
  }
}
```

### Pantalla de planes con detección de retorno desde PayPal

```dart
// lib/screens/plans_screen.dart
import 'package:flutter/material.dart';
import '../services/payment_service.dart';

class PlansScreen extends StatefulWidget {
  final String jwt;
  const PlansScreen({super.key, required this.jwt});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen>
    with WidgetsBindingObserver {

  bool _waitingPaypal  = false;
  bool _loadingMonthly = false;
  bool _loadingYearly  = false;
  bool _checkingStatus = false;
  Map<String, dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSubscription();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Se dispara cuando el usuario regresa a la app desde el browser de PayPal
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingPaypal) {
      _waitingPaypal = false;
      _checkActivation();
    }
  }

  Future<void> _loadSubscription() async {
    final sub = await getSubscription(widget.jwt);
    if (mounted) setState(() => _subscription = sub);
  }

  Future<void> _checkActivation() async {
    setState(() => _checkingStatus = true);
    final sub = await pollUntilActive(widget.jwt);
    if (!mounted) return;
    setState(() {
      _subscription   = sub;
      _checkingStatus = false;
    });
    if (sub == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verificando tu pago... puede tardar unos segundos.')),
      );
    }
  }

  Future<void> _subscribe(String plan) async {
    setState(() => plan == 'yearly' ? _loadingYearly = true : _loadingMonthly = true);
    try {
      final result = await subscribe(widget.jwt, plan);
      await openApprovalPage(result['approveUrl']);
      _waitingPaypal = true; // activado justo después de abrir PayPal
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() { _loadingMonthly = false; _loadingYearly = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingStatus) {
      return const Scaffold(
        body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Verificando pago...'),
          ],
        )),
      );
    }

    final isActive = _subscription?['status'] == 'ACTIVE';

    return Scaffold(
      appBar: AppBar(title: const Text('Planes AgroGraph')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isActive)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '✅ Plan ${_subscription!['planType']} activo\n'
                    'Próximo cobro: ${_subscription!['nextBillingTime']?.substring(0, 10) ?? '—'}',
                  ),
                ),
              )
            else ...[
              // Botón Premium mensual
              FilledButton(
                onPressed: _loadingMonthly ? null : () => _subscribe('monthly'),
                child: _loadingMonthly
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Premium — \$9.99 / mes'),
              ),
              const SizedBox(height: 12),
              // Botón Premium Annual
              FilledButton(
                onPressed: _loadingYearly ? null : () => _subscribe('yearly'),
                child: _loadingYearly
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Premium Annual — \$89.99 / año'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### `pubspec.yaml` — dependencias necesarias

```yaml
dependencies:
  http: ^1.2.0
  url_launcher: ^6.2.0
```

---

## Detector de tipo de tarjeta

Con PayPal el usuario ingresa su tarjeta en la página segura de PayPal (no en tu app). Pero si muestras un campo de tarjeta en alguna pantalla, este widget detecta el tipo mientras el usuario escribe.

### Dart — clase `CardDetector`

```dart
// lib/utils/card_detector.dart
import 'dart:math';

enum CardType { visa, mastercard, amex, discover, unknown }

class CardDetector {
  /// Detecta el tipo de tarjeta a partir del número (parcial o completo).
  static CardType detect(String number) {
    final n = number.replaceAll(RegExp(r'[\s\-]'), '');
    if (n.isEmpty) return CardType.unknown;

    if (RegExp(r'^3[47]').hasMatch(n))                              return CardType.amex;
    if (n.startsWith('4'))                                          return CardType.visa;
    if (RegExp(r'^5[1-5]').hasMatch(n))                            return CardType.mastercard;
    if (RegExp(r'^2(2[2-9][1-9]|[3-6]\d\d|7[01]\d|720)').hasMatch(n)) return CardType.mastercard;
    if (RegExp(r'^(6011|65|64[4-9])').hasMatch(n))                 return CardType.discover;

    return CardType.unknown;
  }

  /// Formatea el número con espacios: 4-4-4-4 (Visa/MC) o 4-6-5 (Amex).
  static String format(String raw, CardType type) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (type == CardType.amex) {
      return [
        digits.substring(0, min(4,  digits.length)),
        if (digits.length > 4)  digits.substring(4,  min(10, digits.length)),
        if (digits.length > 10) digits.substring(10, min(15, digits.length)),
      ].join(' ');
    }
    final groups = <String>[];
    for (var i = 0; i < digits.length; i += 4) {
      groups.add(digits.substring(i, min(i + 4, digits.length)));
    }
    return groups.join(' ');
  }

  /// Máximo de dígitos según el tipo.
  static int maxDigits(CardType type) => type == CardType.amex ? 15 : 16;

  /// Nombre para mostrar en la UI.
  static String label(CardType type) => switch (type) {
    CardType.visa       => 'Visa',
    CardType.mastercard => 'Mastercard',
    CardType.amex       => 'American Express',
    CardType.discover   => 'Discover',
    CardType.unknown    => '',
  };

  /// Emoji representativo para la UI.
  static String icon(CardType type) => switch (type) {
    CardType.visa       => '💳',
    CardType.mastercard => '🔴',
    CardType.amex       => '🔵',
    CardType.discover   => '🟠',
    CardType.unknown    => '💳',
  };
}
```

### Campo de tarjeta con detección en tiempo real

```dart
// Uso en tu widget
CardType _cardType = CardType.unknown;

TextFormField(
  keyboardType: TextInputType.number,
  decoration: InputDecoration(
    labelText: 'Número de tarjeta',
    prefixIcon: const Icon(Icons.credit_card),
    suffixIcon: Text(
      CardDetector.icon(_cardType),
      style: const TextStyle(fontSize: 22),
    ),
    hintText: '1234 5678 9012 3456',
  ),
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(CardDetector.maxDigits(_cardType)),
  ],
  onChanged: (value) {
    final type = CardDetector.detect(value);
    setState(() {
      _cardType = type;
      // El campo se auto-formatea al reescribir el valor
    });
  },
  validator: (value) {
    if (value == null || value.isEmpty) return 'Ingresa el número de tarjeta';
    final digits = value.replaceAll(' ', '');
    if (digits.length < CardDetector.maxDigits(_cardType)) return 'Número incompleto';
    return null;
  },
)
```

**Números de prueba (sandbox)**

| Tipo | Número |
|------|--------|
| Visa | `4111 1111 1111 1111` |
| Mastercard | `5500 0000 0000 0004` |
| Amex | `3714 496353 98431` |
| Discover | `6011 1111 1111 1117` |

---

## Manejo de errores

Todos los errores siguen esta estructura:

```json
{ "error": "Descripción del error", "code": "ERROR_CODE" }
```

| HTTP | `code` | Causa | Qué hacer en la UI |
|------|--------|-------|-------------------|
| `401` | — | JWT inválido, expirado o ausente | Redirigir al login |
| `404` | `SUBSCRIPTION_NOT_FOUND` | El usuario no tiene suscripción | Mostrar pantalla de planes |
| `422` | `PLAN_NOT_FOUND` | Planes no configurados en el servidor | Mostrar error técnico, avisar al backend |
| `400` | `PAYPAL_API_ERROR` | Error en la API de PayPal | Mensaje genérico, permitir reintentar |
| `500` | — | Error interno del servidor | "Intenta más tarde", no reintentar inmediatamente |

```dart
// Patrón de manejo en Flutter
try {
  final result = await subscribe(jwt, plan);
  await openApprovalPage(result['approveUrl']);
} on Exception catch (e) {
  final msg = e.toString().replaceFirst('Exception: ', '');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
```

---

## Checklist de integración

Antes de entregar a QA verifica:

- [ ] Tengo el JWT del usuario **antes** de llamar a `/subscribe`
- [ ] Abro `approveUrl` con `LaunchMode.externalApplication`, **no** en un WebView
- [ ] Mi widget implementa `WidgetsBindingObserver` para detectar el `AppLifecycleState.resumed`
- [ ] Al volver del browser hago polling: hasta 5 reintentos con 3 s entre cada uno
- [ ] Manejo el `404` de `/subscription` sin mostrar error (usuario sin plan es normal)
- [ ] Manejo el `401` redirigiendo al login
- [ ] Muestro un diálogo de confirmación **antes** de llamar a `/cancel`
- [ ] No guardo el JWT en `SharedPreferences` sin cifrar — usar `flutter_secure_storage`
- [ ] **No** llamo a `/webhook` desde la app (es exclusivo para PayPal)
- [ ] El valor de `plan` es exactamente `"monthly"` o `"yearly"` (sin mayúsculas, sin espacios)
