# Conexiones — guía para el equipo móvil

Esta guía es para el equipo que integra la app (AgroGraph-MAS) con los
microservicios de backend. Hay **dos servicios** corriendo en instancias
EC2 separadas; ambos se autentican con el **mismo JWT** (comparten
`JWT_SECRET`), así que un solo token sirve para los dos.

| Servicio | URL base | Qué hace |
|---|---|---|
| Diagnóstico agrícola | `http://52.1.110.21:8000` | Diagnóstico (CNN+RAG+LLM), mapa/alertas epidemiológicas, catálogo offline |
| Notificaciones | `http://3.218.172.128:8100` | Suscripción a alertas por estado/cultivo y push (FCM) |

> **Nota:** por ahora ambos son HTTP plano (sin TLS), IPs públicas fijas de
> las instancias EC2. Si cambian de instancia o se les pone dominio/HTTPS,
> esta guía se actualiza.

---

## 1. Autenticación (JWT)

Los dos servicios validan el mismo token JWT (`Authorization: Bearer <token>`).
El claim que importa es `sub` (id del usuario) y opcionalmente `rol`
(`agricultor` o `aprendiz`).

**Mientras no exista un login real**, el microservicio de diagnóstico
expone un endpoint de desarrollo para generar tokens de prueba (solo activo
con `DEV_MODE=true`, que es como está desplegado ahora):

```http
POST http://52.1.110.21:8000/api/v1/dev/token
Content-Type: application/json

{
  "sub": "usuario123",
  "rol": "agricultor",
  "email": "usuario@ejemplo.com"
}
```

Respuesta:

```json
{
  "access_token": "eyJhbGciOi...",
  "token_type": "bearer",
  "rol": "agricultor",
  "expira_en_horas": 24
}
```

Usa ese `access_token` como `Authorization: Bearer <access_token>` en
**cualquiera** de los dos servicios. Cuando exista un sistema de login real,
este paso cambia, pero el resto de la integración (headers, endpoints) no.

---

## 2. Notificaciones push — flujo completo

### 2.1. Inicializar Firebase en la app

La app debe estar registrada en el **mismo proyecto de Firebase** cuyas
credenciales tiene el backend (si usan un proyecto distinto, el push nunca
va a llegar). Confirma con quien generó `fcm-credenciales.json` cuál es el
proyecto, y agrega `google-services.json` (Android) / `GoogleService-Info.plist`
(iOS) de ese mismo proyecto a la app.

Obtén el token del dispositivo:

```dart
final fcmToken = await FirebaseMessaging.instance.getToken();
```

### 2.2. Suscribirse a alertas de un estado

```http
POST http://3.218.172.128:8100/api/v1/suscripciones
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "fcm_token": "d7Hh...:APA91b...",
  "estado": "Sinaloa",
  "cultivos": ["maiz", "tomate"]
}
```

- `estado`: entidad federativa a vigilar (nombre igual al que devuelve
  `/api/v1/clustering/mapa-campanias` del servicio de diagnóstico).
- `cultivos`: **opcional**. Si se manda, solo llegan alertas cuyo cultivo
  dominante coincide con alguno de la lista (usa los mismos nombres que
  "Mis cultivos" en la app). Si se omite (`null` o no mandarlo), llegan
  todas las alertas de ese estado.

Respuesta (201/200):

```json
{
  "user_id": "usuario123",
  "fcm_token": "d7Hh...:APA91b...",
  "estado": "Sinaloa",
  "cultivos": ["maiz", "tomate"],
  "creado": "2026-07-12T01:00:00+00:00",
  "actualizado": "2026-07-12T01:00:00+00:00"
}
```

Volver a llamar este mismo endpoint (con el mismo token de usuario)
**actualiza** la suscripción existente — por ejemplo, si el usuario cambia
de estado o reinstala la app y le cambia el `fcm_token`.

### 2.3. Consultar mi suscripción

```http
GET http://3.218.172.128:8100/api/v1/suscripciones/yo
Authorization: Bearer <access_token>
```

`404` si el usuario no tiene ninguna suscripción activa.

### 2.4. Cancelar la suscripción

```http
DELETE http://3.218.172.128:8100/api/v1/suscripciones/yo
Authorization: Bearer <access_token>
```

Llamar esto cuando el usuario desactiva las notificaciones desde ajustes.

### 2.5. Recibir el push

No hay nada más que hacer del lado de la app: el backend revisa cada hora
(configurable) si cambió la campaña dominante del estado suscrito, y si es
así, manda un push normal de FCM:

```json
{
  "notification": {
    "title": "Alerta fitosanitaria en Sinaloa",
    "body": "Campaña activa en Sinaloa: <nombre de campaña> (<cultivo>)."
  },
  "data": {
    "estado": "Sinaloa",
    "campania": "<nombre de campaña>"
  }
}
```

Se maneja como cualquier notificación de FCM (foreground/background) — usa
el `data.estado` si quieren llevar al usuario directo a la pantalla del
mapa epidemiológico filtrada por ese estado al tocar la notificación.

---

## 3. Endpoints de diagnóstico y mapa epidemiológico

Documentados en el README del microservicio de diagnóstico agrícola
(`/consultar`, `/clustering/mapa-campanias`, `/alertas`, catálogo offline,
etc). Swagger interactivo:

```
http://52.1.110.21:8000/docs
```

## 4. Swagger del servicio de notificaciones

```
http://3.218.172.128:8100/docs
```

---

## 5. Errores comunes

| Código | Causa | Qué revisar |
|---|---|---|
| 401 | Token ausente, vencido o firmado con otro secreto | Regenerar token con `/api/v1/dev/token`; confirmar que no pasó `expira_en_horas` |
| 404 en `/suscripciones/yo` | El usuario nunca se suscribió | Llamar primero a `POST /api/v1/suscripciones` |
| No llega el push | Proyecto de Firebase distinto entre app y backend, o `fcm_token` vencido | Confirmar mismo proyecto Firebase; volver a suscribir con un `fcm_token` fresco |
| No llega el push aunque todo lo anterior está bien | Puede que la campaña dominante del estado no haya cambiado todavía (el chequeo es cada hora y solo notifica ante un cambio, no en cada corrida) | Nada que hacer del lado móvil; es comportamiento esperado |
