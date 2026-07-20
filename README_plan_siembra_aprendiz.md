# Plan de siembra del Aprendiz — ya implementado y desplegado (GPU)

> Responde a lo pendiente en `README_FRONTEND_APRENDIZ_SIEMBRA.md` (sección 7,
> "fuera de alcance"): el plan de actividades para el cultivo de práctica.
> Reutiliza el MISMO mecanismo de agenda que ya usa el flujo de diagnóstico —
> no hay endpoint de agenda nuevo, no hay modelo nuevo.

---

## 1. Qué se implementó

Un endpoint nuevo y chico en el backend de LLM (misma GPU que ya usan para
`/consultar` y `/{rol}/agenda/generar`) que genera el **texto** del plan de
siembra vía Qwen. Ese texto se pasa tal cual a la agenda que ya existe.

**Host:** `http://18.190.223.177:8000` (mismo que `llmBaseUrl`)
**Auth:** mismo JWT Bearer de siempre.

## 2. El flujo completo (2 llamadas, ambas ya existentes o nuevas-chicas)

```
1) Usuario registra su cultivo de práctica
   POST http://3.217.217.227/api/v1/selecciones   (microservicio Cultivos, ya implementado)
        ↓ éxito
2) App pide el texto del plan (NUEVO endpoint, GPU)
   POST http://18.190.223.177:8000/api/v1/aprendiz/plan-siembra
   Body: { "cultivo": "Maíz", "lugar_practica": "jardin_casa" }
   → { "cultivo": "Maíz", "lugar_practica": "jardin_casa",
       "texto": "- Prepara el sustrato...\n- Siembra las semillas...\n..." }
        ↓
3) App arma la agenda con ESE texto (endpoint que YA USAN para el
   diagnóstico — mismo `GenerateAgendaUseCase` / `AgendaRepository` rol
   'aprendiz' que ya tienen conectado)
   POST http://18.190.223.177:8000/api/v1/aprendiz/agenda/generar
   Body: {
     "cultivo": "Maíz",
     "enfermedad": "",
     "tratamiento": "<el texto del paso 2>",
     "prevencion": ""
   }
   → AgendaOverview con las actividades (misma respuesta que ya manejan)
```

**No hay tabla ni endpoint de agenda nuevo.** El paso 3 es exactamente la
misma llamada que ya hace `AprendizRecommendedActionPage._addToAgenda()`
tras un diagnóstico — aquí solo cambia qué le mandan como `tratamiento`
(el plan de siembra en vez del tratamiento de una enfermedad) y `enfermedad`
va vacío.

## 3. Contrato del endpoint nuevo

```
POST /api/v1/aprendiz/plan-siembra
Authorization: Bearer <jwt>
Content-Type: application/json
```
```json
{ "cultivo": "Tomate", "lugar_practica": "jardin_casa" }
```
- `cultivo`: nombre del cultivo (el mismo string que ya usan, no hace falta
  el `cultivo_id`/UUID del microservicio de Cultivos).
- `lugar_practica`: **el mismo enum** que ya definieron con Cultivos —
  `"jardin_casa"` \| `"invernadero"` — mapeen `CropPracticeLocation.home` /
  `.greenhouse` igual que ya hacen para `POST /selecciones`.

**Respuesta (`200`):**
```json
{
  "cultivo": "Tomate",
  "lugar_practica": "jardin_casa",
  "texto": "- Prepara el sustrato para tus tomates en macetas...\n- Siembra las semillas...\n- Coloca tus macetas donde reciba al menos 6 horas de luz solar...\n- Comienza a regar regularmente...\n- Monitorea tus plantas cada día..."
}
```
- 4-6 líneas con guion, cada una una acción concreta, **nunca menciona
  productos/fertilizantes/pesticidas** (mismo estándar de seguridad que ya
  aplican al resto del perfil aprendiz).
- Verificado con Tomate/jardín y Maíz/invernadero — pasos coherentes,
  adaptados al lugar (drenaje en maceta vs. ventilación en invernadero).

**Errores:** `401` (token inválido), `422` (`lugar_practica` fuera del enum),
`503` (Ollama no disponible — mismo comportamiento que `/consultar`).

## 4. Cuándo llamarlo

Justo después de que `POST /selecciones` responde `201` (registro del cultivo
de práctica exitoso) — encadenan paso 2 y paso 3 automáticamente, sin que el
usuario tenga que pedirlo con un botón (a diferencia del flujo de
diagnóstico, donde el usuario elige "Agregar a mi agenda"). Si prefieren
mantenerlo manual con un botón, funciona igual — es la misma llamada.

## 5. Qué NO cambia
- El endpoint de agenda (`/aprendiz/agenda/generar`) es el mismo de siempre,
  sin parámetros nuevos.
- El microservicio de Cultivos (registro del cultivo) no se tocó.
- No hay cambios en `LlmResponseEntity` ni en el flujo de diagnóstico.
