# AgroGrap — Guía de correcciones para el equipo Backend

> **Alcance:** Microservicio LLM (Python / FastAPI / Ollama)  
> **Fecha:** Julio 2026  
> **Fuente:** Logs reales capturados desde la app móvil Flutter  
> **Estado del frontend:** Corregido en su totalidad — todos los cambios pendientes son del lado del servidor.

---

## Resumen ejecutivo

Se identificaron **tres bugs confirmados** con evidencia en logs de producción. Los tres tienen causa precisa y corrección puntual. El cliente móvil ya envía `rol: "agricultor"` o `rol: "aprendiz"` correctamente según el tipo de usuario. Los timeouts y reintentos son del lado del servidor.

---

## Tabla de prioridades

| # | Problema | Archivo | Impacto | Urgencia |
|---|----------|---------|---------|----------|
| 1 | Cold start: primer request tarda 300 s y da 503 | `main.py` / startup | Usuario nunca recibe respuesta en primer uso | **CRÍTICO** |
| 2 | Campo `rol` del request ignorado — responde siempre como Aprendiz | Handler `/api/v1/consultar` | Agricultor recibe respuestas incorrectas sin dosis ni productos | **CRÍTICO** |
| 3 | `_extraer_secciones` no detecta encabezados markdown del modelo | `modulos/generador.py` | Campos `diagnostico/tratamiento/prevencion` llegan vacíos al cliente | **ALTO** |

---

## Problema 1 — Cold start de Ollama (300 s de espera)

**Síntoma:** Timeout de 150 s en el primer request → 503. El segundo intento responde con normalidad.

### Evidencia del log

```
[HTTP →]  POST /api/v1/consultar
          body: {..., rol: aprendiz}
[HTTP ✗]  503  — Ollama no respondió en 150s. El modelo puede estar cargando; reintenta.
          ← usuario presiona "Reintentar" ~150 s después
[HTTP →]  POST /api/v1/consultar
[HTTP ←]  200  /api/v1/consultar  ← segunda vez sí responde
```

### Causa raíz

Ollama carga el modelo en RAM (GPU/CPU) la primera vez que recibe un request. Si ese proceso tarda más de 150 s (el timeout configurado en el backend), la petición aborta con `503`. El modelo queda cargado en memoria, por eso el segundo intento responde normalmente. Esto ocurre siempre que el servidor se reinicia o cuando Ollama libera el modelo por inactividad.

---

### Solución A — Warm-up al iniciar el servidor *(recomendada)*

Enviar un prompt mínimo a Ollama durante el startup de FastAPI. El servidor no acepta requests de usuarios hasta que el modelo esté listo.

```python
# main.py
from contextlib import asynccontextmanager
import httpx
import logging

logger = logging.getLogger(__name__)

OLLAMA_URL    = "http://localhost:11434"
OLLAMA_MODEL  = "llama3.2:1b"   # ajustar al modelo real
OLLAMA_TIMEOUT = 300             # subir de 150 → 300 para absorber carga fría

@asynccontextmanager
async def lifespan(app):
    # Warm-up: carga el modelo antes de aceptar tráfico
    logger.info("[startup] Calentando modelo Ollama...")
    try:
        async with httpx.AsyncClient(timeout=300) as client:
            await client.post(
                f"{OLLAMA_URL}/api/generate",
                json={
                    "model":   OLLAMA_MODEL,
                    "prompt":  "hola",
                    "stream":  False,
                    "options": {"num_predict": 1},
                },
            )
        logger.info("[startup] Modelo cargado y listo.")
    except Exception as e:
        logger.warning(f"[startup] Warm-up falló: {e}. El primer request puede tardar.")
    yield
    # cleanup al apagar (opcional)

app = FastAPI(lifespan=lifespan)
```

---

### Solución B — Aumentar timeout *(mínimo indispensable)*

Si el warm-up no es viable de inmediato, aumentar el timeout evita el 503 aunque el cold start siga siendo lento.

```python
# ANTES
OLLAMA_TIMEOUT = 150

# DESPUÉS
OLLAMA_TIMEOUT = 300  # absorbe cold start; ajustar según RAM disponible
```

---

### Solución C — Keep-alive de Ollama *(complementaria)*

Configurar Ollama para mantener el modelo en memoria más tiempo entre peticiones:

```bash
# Mantiene el modelo cargado 10 minutos sin peticiones (default: 5 min)
OLLAMA_KEEP_ALIVE="10m"

# O permanente mientras el proceso esté vivo:
OLLAMA_KEEP_ALIVE="-1"
```

> **Resultado esperado:** El primer request de cualquier usuario llega con el modelo ya en memoria. Tiempo de respuesta: igual al de los requests subsiguientes, sin 503. El warm-up solo añade tiempo al arranque del servidor, no al usuario.

---

## Problema 2 — Campo `rol` del request ignorado

**Síntoma:** El frontend envía `rol: "agricultor"` pero el backend responde con contenido de Aprendiz (tono pedagógico, sin dosis ni productos).

### Evidencia del log

```
REQUEST   body.rol       = "agricultor"    ← frontend envía correcto
RESPONSE  respuesta.rol  = "aprendiz"      ← backend responde con rol incorrecto

RESPONSE  texto: "Hola agricultor. Entiendo perfectamente tu situación...
           ...no estás solo y que la calabaza es una planta muy resistente..."
           ← tono de mentor/aprendiz, no técnico de agricultor
```

### Causa raíz

El handler de `/api/v1/consultar` no lee `body.rol` para seleccionar el prompt de sistema. Usa el **rol del JWT** del usuario o un **default hardcodeado** (`"aprendiz"`). El campo `rol` llega en el body pero se descarta.

### Diferencia entre los prompts de sistema

| Aspecto | rol: aprendiz | rol: agricultor |
|---------|---------------|-----------------|
| Tono | Pedagógico, mentor, "no estás solo" | Técnico, directo, profesional |
| Productos | Sin nombres comerciales ni dosis | Nombra productos y dosis específicas |
| Longitud | Explicativa, con analogías | Concisa, orientada a acción |
| Pregunta al final | Sí, para guiar al aprendiz | No obligatoria |

---

### Fix 1 — Agregar `rol` al schema Pydantic del request

```python
# schemas.py (o donde esté ConsultaRequest)
from pydantic import BaseModel, Field
from typing import Optional, Literal

class ResultadoCNN(BaseModel):
    cultivo:        str
    enfermedad:     str
    confianza:      float
    clase_cnn:      str
    confianza_baja: bool

class ConsultaRequest(BaseModel):
    resultado_cnn: ResultadoCNN
    cultivos:      list[str]
    texto:         Optional[str] = None
    rol:           Literal["agricultor", "aprendiz"] = "aprendiz"  # ← AGREGAR
```

---

### Fix 2 — Leer `rol` en el handler y seleccionar el prompt

```python
# routers/consultar.py (o donde esté el endpoint)
@router.post("/api/v1/consultar")
async def consultar(
    body:         ConsultaRequest,
    current_user: User = Depends(get_current_user),
):
    # ── ANTES (causa del bug) ──────────────────────────────────
    # rol = current_user.rol          # ignora el body
    # rol = "aprendiz"                # hardcodeado

    # ── DESPUÉS ────────────────────────────────────────────────
    rol = body.rol  # Pydantic ya validó que es "agricultor" | "aprendiz"

    # Seleccionar el prompt de sistema según el rol
    system_prompt = get_system_prompt(rol)

    # ... resto del handler (llamada a Ollama, etc.) ...
    respuesta = await generador.generar(
        resultado_cnn = body.resultado_cnn,
        texto_usuario = body.texto,
        system_prompt = system_prompt,
        rol           = rol,
    )

    # Devolver el rol usado para trazabilidad
    return {
        "modo":        "online",
        "diagnostico": respuesta.diagnostico_obj,
        "respuesta":   respuesta.texto_obj,
        "rol":         rol,   # confirmar el rol real usado
        "sintomas":    respuesta.sintomas,
        "avisos":      respuesta.avisos,
    }
```

---

### Fix 3 — Función `get_system_prompt` con prompts diferenciados

```python
# modulos/prompts.py
def get_system_prompt(rol: str) -> str:
    if rol == "agricultor":
        return """Eres un asistente agronómico técnico para agricultores experimentados.
Responde de forma directa y profesional. Incluye:
- Nombres comerciales de productos fitosanitarios cuando sean relevantes.
- Dosis exactas según el cultivo y la etapa fenológica.
- Mecanismos de acción de los tratamientos recomendados.
- Referencias a normativa vigente (SENASICA, MAPA, etc.) si aplica.
No uses lenguaje pedagógico ni tutorías. El agricultor conoce su campo."""

    return """Eres un mentor agrícola para aprendices que están comenzando.
Usa un tono amable y pedagógico. Explica el por qué de cada paso.
NO menciones nombres comerciales ni dosis de productos químicos;
en su lugar, explica el tipo de tratamiento e indica consultar con
un agrónomo o agricultor experimentado para elegir el producto."""
```

> **Resultado esperado:** Un agricultor que envía `rol: "agricultor"` recibe una respuesta técnica con nombres de fungicidas, dosis y referencias. Un aprendiz que envía `rol: "aprendiz"` recibe una explicación pedagógica sin productos. El campo `respuesta.rol` en la respuesta confirma qué perfil se usó.

---

## Problema 3 — Extracción de secciones falla con formato markdown

**Síntoma:** `respuesta.diagnostico`, `respuesta.tratamiento` y `respuesta.prevencion` llegan vacíos (`""`) al cliente aunque `respuesta.texto` contiene el contenido completo.

### Evidencia del log

```
RESPONSE  respuesta.texto:
          "...### DIAGNÓSTICO\nEl maíz está afectado...\n### TRATAMIENTO\n..."
          ← modelo genera encabezados con ### (markdown), sin ":"

RESPONSE  respuesta.diagnostico = ""   ← vacío
RESPONSE  respuesta.tratamiento = ""   ← vacío
RESPONSE  respuesta.prevencion  = ""   ← vacío
```

### Causa raíz

El modelo LLM (0.8B) no sigue instrucciones de formato con precisión perfecta. El prompt le pide `DIAGNÓSTICO:` (sin `#`, con `:`) pero genera `### DIAGNÓSTICO` (con markdown, sin `:`, o con variantes como `### FUENTES RELEVANTES` en vez de `FUENTES:`). La función `_extraer_secciones` busca coincidencias exactas y no encuentra nada → devuelve strings vacíos.

---

### Fix — Regex tolerante en `_extraer_secciones`

```python
# modulos/generador.py
import re

def _extraer_secciones(texto: str) -> dict:
    # ── ANTES ── búsqueda exacta, sin tolerancia al modelo
    # patrones = {
    #     "diagnostico": r"DIAGNÓSTICO:",
    #     "tratamiento": r"TRATAMIENTO:",
    #     "prevencion":  r"PREVENCIÓN:",
    #     "preguntas":   r"PREGUNTAS:",
    #     "fuentes":     r"FUENTES:",
    # }

    # ── DESPUÉS ── prefijo markdown opcional, ":" opcional, variantes de FUENTES
    PREFIJO = r"(?:#{1,4}\s*)?"   # acepta #, ##, ###, #### o nada
    SEP     = r"[:\s]"            # acepta ":" o espacio/salto de línea
    patrones = {
        "diagnostico": PREFIJO + r"DIAGNÓSTICO"         + SEP,
        "tratamiento": PREFIJO + r"TRATAMIENTO"         + SEP,
        "prevencion":  PREFIJO + r"PREVENCI[OÓ]N"      + SEP,  # acepta Ó u O
        "preguntas":   PREFIJO + r"PREGUNTAS"           + SEP,
        "fuentes":     PREFIJO + r"FUENTES(?:\s+\w+)*"  + SEP,  # FUENTES RELEVANTES, CONSULTADAS, etc.
    }

    resultado  = {}
    claves     = list(patrones.keys())
    posiciones = {}

    # Encontrar posición de cada encabezado en el texto
    for clave, patron in patrones.items():
        m = re.search(patron, texto, re.IGNORECASE | re.MULTILINE)
        if m:
            posiciones[clave] = m.end()  # posición donde empieza el contenido

    # Extraer contenido entre encabezados consecutivos
    posiciones_ordenadas = sorted(posiciones.items(), key=lambda x: x[1])

    for i, (clave, inicio) in enumerate(posiciones_ordenadas):
        fin = posiciones_ordenadas[i + 1][1] - 1 \
              if i + 1 < len(posiciones_ordenadas) \
              else len(texto)
        resultado[clave] = texto[inicio:fin].strip()

    # Garantizar que todas las claves existan aunque el modelo no las genere
    for clave in claves:
        resultado.setdefault(clave, "")

    return resultado
```

> **Nota sobre truncación:** En algunos logs se observa `prevencion: "1.  Mantener los"` — el modelo dejó de generar a mitad de una lista. Esto no es un bug de la extracción sino un **límite de tokens** de Ollama. Verificar y aumentar `num_predict` (o `max_tokens`) en la llamada al modelo si las respuestas se cortan frecuentemente. Valor sugerido: **≥ 1024 tokens**.

---

## Tests unitarios a agregar

Correr **antes y después** de aplicar los fixes para confirmar regresión cero.

```python
# tests/test_generador.py
import pytest
from modulos.generador import _extraer_secciones

TEXTO_MARKDOWN = """Hola agricultor. Aquí el análisis del sistema.

### DIAGNÓSTICO
El cultivo de maíz presenta síntomas de tizón norteño foliar causado por
Exserohilum turcicum. Confianza del modelo: 0.97.

### TRATAMIENTO
Aplicar fungicida sistémico (propiconazol 250 EC) en las primeras etapas.
Paso 1: retirar hojas severamente afectadas.
Paso 2: aplicar fungicida según etiqueta.

### PREVENCIÓN
1. Usar variedades resistentes.
2. Rotación de cultivos cada temporada.
3. Evitar riego excesivo en periodos cálidos.

### FUENTES RELEVANTES
* CIMMYT — Enfermedades del Maíz 2021
* Guía GIP Maíz — MAPA España
"""

TEXTO_CLASICO = """DIAGNÓSTICO:
El cultivo de tomate presenta síntomas de tizón temprano.

TRATAMIENTO:
Aplicar mancozeb 80 WP.

PREVENCIÓN:
Evitar monocultivo.

FUENTES:
Guía Fitopatología 2020
"""

def test_extraer_formato_markdown():
    # Formato real que produce el modelo (### sin ":")
    r = _extraer_secciones(TEXTO_MARKDOWN)
    assert "tizón norteño"  in r["diagnostico"],  "diagnostico vacío con ### header"
    assert "propiconazol"   in r["tratamiento"],  "tratamiento vacío con ### header"
    assert "variedades"     in r["prevencion"],   "prevencion vacía con ### header"
    assert r["fuentes"] != "",                    "fuentes vacías con '### FUENTES RELEVANTES'"

def test_extraer_formato_clasico():
    # Formato original con ":" — no debe romper
    r = _extraer_secciones(TEXTO_CLASICO)
    assert "tizón temprano" in r["diagnostico"]
    assert "mancozeb"       in r["tratamiento"]
    assert "monocultivo"    in r["prevencion"]
    assert "Fitopatología"  in r["fuentes"]

def test_extraer_secciones_incompletas():
    # Modelo trunca — debe devolver lo que hay, sin lanzar excepción
    texto_truncado = "### DIAGNÓSTICO\nEl cultivo de papa presenta...\n\n### PREVENCIÓN\n1. Mantener"
    r = _extraer_secciones(texto_truncado)
    assert r["diagnostico"] != ""
    assert r["tratamiento"]  == ""  # no apareció en el texto
    assert "Mantener"  in r["prevencion"]
```

```bash
# Solo los tests de generador
pytest tests/test_generador.py -v

# Suite completa + cobertura
pytest --tb=short -v
```

---

## Checklist de verificación final

Confirmar cada punto con un request real desde la app antes de cerrar los cambios.

- [ ] **1. Cold start resuelto** — Reiniciar el servidor. El primer `POST /api/v1/consultar` (sin ningún request previo) debe responder en menos de 20 segundos con `200`, no `503`. El log de startup debe mostrar `[startup] Modelo cargado y listo.`

- [ ] **2. Agricultor recibe respuesta técnica** — Enviar `POST /api/v1/consultar` con `rol: "agricultor"`. La respuesta **debe incluir** nombres comerciales de productos y/o dosis. El campo `respuesta.rol` en el JSON de respuesta debe ser `"agricultor"`.

- [ ] **3. Aprendiz recibe respuesta pedagógica** — Enviar `POST /api/v1/consultar` con `rol: "aprendiz"`. La respuesta **no debe** mencionar productos con dosis específicas. Tono amable y explicativo. `respuesta.rol` = `"aprendiz"`.

- [ ] **4. Campos de sección no vacíos** — En el JSON de respuesta, `respuesta.diagnostico`, `respuesta.tratamiento` y `respuesta.prevencion` deben tener contenido (no `""`). Verificar con cualquier cultivo que el modelo genere los tres encabezados.

- [ ] **5. Tests pasan sin errores** — Ejecutar `pytest tests/test_generador.py -v`. Los tres tests nuevos (`test_extraer_formato_markdown`, `test_extraer_formato_clasico`, `test_extraer_secciones_incompletas`) deben estar en verde. La suite previa no debe tener nuevas regresiones.

- [ ] **6. Respuestas completas (no truncadas)** — Revisar que `respuesta.prevencion` no termina a mitad de frase. Si sigue truncándose, aumentar `num_predict` / `max_tokens` en la llamada a Ollama (valor sugerido: ≥ 1024 tokens para respuestas completas).

---

## Estado del frontend Flutter

No se requieren cambios adicionales en la app móvil. El cliente ya:

- Envía `rol: "agricultor"` o `rol: "aprendiz"` en el body de cada request.
- Parsea el response con fallbacks robustos (`respuesta.texto` como último recurso).
- Maneja correctamente los estados de error y carga.

Una vez que el backend aplique estos tres fixes, la app funcionará sin modificaciones adicionales.
