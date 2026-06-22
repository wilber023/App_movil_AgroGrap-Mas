# Flujo de Vistas — Perfil Productor Guiado (Aprendiz)
> AgroGraph-MAS · Documento de referencia para maquetado
> Excluye: Login y Registro de cuenta (ya funciona). Incluye todo desde que el usuario entra con sesión activa.

---

## Sistema de diseño (tokens de referencia)

| Token | Valor |
|---|---|
| Verde oscuro (header/nav activo) | `#1B4332` |
| Verde medio (acciones primarias) | `#2D6A4F` |
| Verde claro (fondo tarjetas) | `#D8F3DC` |
| Naranja (CTA principal / alertas) | `#F4845F` |
| Amarillo suave (pendientes) | `#FFF3CD` |
| Rojo suave (detección enfermedad) | `#FFE5E5` |
| Fondo general | `#F0FAF3` |
| Texto principal | `#1A1A1A` |
| Texto secundario | `#6B7280` |
| Border-radius tarjeta | `12px` |
| Border-radius botón | `10px` |

**Navbar inferior (presente en TODAS las vistas principales):**
5 tabs: `Inicio` · `Diagnóstico` · `Mi Cultivo` · `Agenda` · `Perfil`
Ícono activo: verde oscuro `#1B4332`. El tab de **Mi Cultivo** usa ícono de planta 🌱.

---

## 1. Diagrama general — Mapa completo del sistema

```mermaid
flowchart TD
    LOGIN([✅ Login exitoso]) --> GUARD{¿Tiene cultivo\nregistrado?}

    GUARD -- NO --> V1[📋 Vista 1\nRegistro de Cultivo]
    V1 --> GENPLAN[⚙️ Genera plan de\nactividades automático\nsin IA - plantillas]
    GENPLAN --> V0

    GUARD -- SÍ --> V0[🏠 Vista 0\nHome / Inicio]

    V0 --> TAB_DIAG[🔬 Tab Diagnóstico]
    V0 --> TAB_CULTIVO[🌱 Tab Mi Cultivo]
    V0 --> TAB_AGENDA[📆 Tab Agenda]
    V0 --> TAB_PERFIL[👤 Tab Perfil]
    V0 --> NOTIF[🔔 Notificación push\no modal de inspección]

    TAB_CULTIVO --> V2[Vista 2\nRuta del Cultivo]
    V2 --> V2B[Vista 2b\nEstado de mi Cultivo]
    V2 --> TAB_DIAG

    TAB_DIAG --> V3[Vista 3\nDiagnóstico / Cámara]
    NOTIF --> MODAL8[Modal 8\nInspección Programada]
    MODAL8 --> V3

    V3 --> CNN[⚙️ Microservicio CNN\nProcesa imagen]
    CNN --> V4[Vista 4\nResultado Diagnóstico]

    V4 --> V5[Vista 5\nAcción Recomendada]
    V4 --> V7[Vista 7\nHistorial del Cultivo]

    V5 --> MODAL5B[Modal 5b\nConfirmación Agenda]
    MODAL5B --> TAB_AGENDA

    TAB_AGENDA --> V6[Vista 6\nAgenda]
    V0 --> V7

    style LOGIN fill:#D8F3DC,stroke:#1B4332
    style GUARD fill:#FFF3CD,stroke:#F4845F
    style CNN fill:#D8F3DC,stroke:#2D6A4F
    style GENPLAN fill:#D8F3DC,stroke:#2D6A4F
    style V0 fill:#1B4332,color:#fff
    style NOTIF fill:#FFE5E5,stroke:#F4845F
    style MODAL8 fill:#FFE5E5,stroke:#F4845F
    style MODAL5B fill:#D8F3DC,stroke:#1B4332
```

---

## 2. Diagrama — Flujo de primera entrada (onboarding del cultivo)

> Ocurre una única vez: cuando el usuario entra por primera vez o no tiene cultivo registrado.

```mermaid
flowchart TD
    START([Usuario abre la app\nSesión activa]) --> CHECK{¿Cultivo\nregistrado?}
    CHECK -- SÍ --> HOME[🏠 Home]
    CHECK -- NO --> REG[📋 Pantalla Registro de Cultivo]

    REG --> PASO1[Paso 1\n¿Qué vas a sembrar?\nGrid de cultivos]
    PASO1 --> SEL{¿Seleccionó\nun cultivo?}
    SEL -- NO --> PASO1
    SEL -- SÍ --> PASO2[Paso 2\nFecha de siembra\nDate picker]

    PASO2 --> FECHA{¿Ingresó\nfecha?}
    FECHA -- NO --> PASO2
    FECHA -- SÍ --> MOSTRAR_COSECHA[Muestra badge:\n'Cosecha estimada: 15 ago 2026']
    MOSTRAR_COSECHA --> PASO3[Paso 3\nSuperficie\nNúmero + unidad]

    PASO3 --> SUP{¿Ingresó\nsuperficie?}
    SUP -- NO --> PASO3
    SUP -- SÍ --> PREVIEW[Muestra preview del plan:\n'18 semanas de actividades\npara Maíz']
    PREVIEW --> BTN_ACTIVO[Botón 'Generar mi plan'\nse activa en naranja]

    BTN_ACTIVO --> GENERAR[⚙️ Sistema genera\nplan de plantillas\nsin intervención de IA]
    GENERAR --> HOME[🏠 Home con cultivo activo]

    style START fill:#D8F3DC,stroke:#1B4332
    style HOME fill:#1B4332,color:#fff
    style GENERAR fill:#D8F3DC,stroke:#2D6A4F
    style PREVIEW fill:#D8F3DC,stroke:#2D6A4F
    style BTN_ACTIVO fill:#F4845F,color:#fff
```

---

## 3. Diagrama — Flujo del ciclo de diagnóstico (núcleo del sistema)

> Este es el flujo más importante. Ocurre cada vez que el usuario realiza una inspección, ya sea programada o libre.

```mermaid
flowchart TD
    ENTRADA([¿Cómo llega el usuario\nal diagnóstico?]) --> OPC1[Tab 'Diagnóstico'\nen navbar]
    ENTRADA --> OPC2[Botón 'Ir a inspección'\ndesde Home]
    ENTRADA --> OPC3[Notificación push\no Modal de inspección]
    ENTRADA --> OPC4[Botón 'Realizar\ninspección ahora'\ndesde Mi Cultivo]

    OPC1 --> V3[Vista 3\nDiagnóstico / Cámara]
    OPC2 --> V3
    OPC3 --> MODAL8[Modal 8\n'Es momento de\ninspeccionar']
    OPC4 --> V3
    MODAL8 --> ACCION{¿Qué hace\nel usuario?}
    ACCION -- "Ir a diagnóstico →" --> V3
    ACCION -- "Posponer para mañana" --> HOME[🏠 Home\nActividad reprogramada +1 día]

    V3 --> BANNER{¿Viene de\ninspección programada?}
    BANNER -- SÍ --> MOSTRAR_BANNER[Muestra banner contextual\n'INSPECCIÓN PENDIENTE · SEMANA 6'\nMaíz · Milpa Norte]
    BANNER -- NO --> CAM_LIBRE[Área de cámara libre]
    MOSTRAR_BANNER --> CAM_LIBRE

    CAM_LIBRE --> FOTO{¿Cómo obtiene\nla foto?}
    FOTO -- "Tomar foto" --> CAMARA[📷 Cámara nativa\nAndroid]
    FOTO -- "Elegir de galería" --> GALERIA[🖼️ Galería del dispositivo]

    CAMARA --> IMG[Imagen seleccionada\nMiniatura visible en pantalla]
    GALERIA --> IMG

    IMG --> DESC[Descripción adicional\nopcional · 0/300 chars]
    DESC --> BTN_ANALIZAR[Botón 'Analizar foto →'\nse activa en naranja]
    BTN_ANALIZAR --> SPINNER[⏳ Spinner\n'Analizando tu cultivo...']
    SPINNER --> CNN[⚙️ Microservicio CNN\nIdentifica planta + enfermedad]

    CNN --> CONFIANZA{Nivel de\nconfianza?}
    CONFIANZA -- "> 60%" --> V4[Vista 4\nResultado del Diagnóstico]
    CONFIANZA -- "< 60%" --> BAJA_CONF[Banner amarillo\n'Imagen poco clara,\nintenta con mejor\niluminación']
    BAJA_CONF --> REINTENTAR[Botón 'Intentar de nuevo'\nvuelve a Vista 3]

    V4 --> RESULTADO{¿Qué detectó\nla CNN?}
    RESULTADO -- "Enfermedad detectada" --> ENFER[Card roja\nTizón tardío · 91%\nIntervención recomendada]
    RESULTADO -- "Sin patología" --> SANO[Card verde\nSin patología · 88%\nPlanta en buen estado]

    ENFER --> V5[Vista 5\nAcción Recomendada]
    SANO --> GUARDAR[Botón 'Guardar\nen historial'\nregistro automático]
    V5 --> DECISION{¿Acepta la\nrecomendación?}

    DECISION -- "Agregar a mi agenda →" --> MODAL5B[Modal 5b\nConfirmación de Agenda\n3 actividades creadas automáticamente]
    DECISION -- "Rechazar recomendación" --> HOME

    MODAL5B --> VER_AGENDA[Botón 'Ver mi agenda →']
    VER_AGENDA --> V6[Vista 6\nAgenda]
    GUARDAR --> V7[Vista 7\nHistorial del Cultivo]

    style CNN fill:#D8F3DC,stroke:#2D6A4F
    style SPINNER fill:#FFF3CD,stroke:#F4845F
    style ENFER fill:#FFE5E5,stroke:#cc0000
    style SANO fill:#D8F3DC,stroke:#1B4332
    style BTN_ANALIZAR fill:#F4845F,color:#fff
    style MODAL5B fill:#D8F3DC,stroke:#1B4332
    style BAJA_CONF fill:#FFF3CD,stroke:#F4845F
```

---

## 4. Diagrama — Flujo de notificaciones y recordatorios

> Describe cuándo y cómo el sistema interrumpe al usuario para guiarlo.

```mermaid
flowchart TD
    SISTEMA([⚙️ Sistema AgroGraph-MAS\nmonitor de plan activo]) --> EVAL[Evalúa diariamente\nactividades del plan]

    EVAL --> VENCE{¿Hay actividad\npróxima a vencer?}
    VENCE -- NO --> EVAL
    VENCE -- SÍ --> TIPO_NOTIF{¿Tipo de\nactividad?}

    TIPO_NOTIF -- "Inspección programada\n(semana actual)" --> PUSH_INSP[🔔 Notificación push:\n'Inspección semanal\nrequerida · Semana 6']
    TIPO_NOTIF -- "Fertilización mañana" --> PUSH_FERT[🔔 Notificación push:\n'Fertilización mañana\nMaíz · Milpa Norte']
    TIPO_NOTIF -- "Han pasado 14 días\ndesde última revisión" --> PUSH_REV[🔔 Notificación push:\n'Han pasado 14 días\ndesde tu última revisión']
    TIPO_NOTIF -- "Seguimiento post-tratamiento\n7 días después" --> PUSH_SEG[🔔 Notificación push:\n'Revisa el tratamiento\naplicado hace 7 días']

    PUSH_INSP --> ABRE{¿El usuario\nabre la app?}
    PUSH_FERT --> ABRE
    PUSH_REV --> ABRE
    PUSH_SEG --> ABRE

    ABRE -- SÍ --> MODAL8[Modal 8\n'Es momento de inspeccionar'\nSemana 6 · Inspección programada]
    ABRE -- NO --> RECORDATORIO[Sistema reintenta\nen 2 horas]

    MODAL8 --> RESP_MODAL{¿Qué responde\nel usuario?}
    RESP_MODAL -- "Ir a diagnóstico →" --> V3[Vista 3\nDiagnóstico / Cámara]
    RESP_MODAL -- "Posponer para mañana" --> POSPONE[Sistema marca\nactividad como POSPUESTA\nReprograma +1 día]
    POSPONE --> HOME[🏠 Home]

    style SISTEMA fill:#D8F3DC,stroke:#2D6A4F
    style PUSH_INSP fill:#FFE5E5,stroke:#F4845F
    style PUSH_FERT fill:#FFF3CD,stroke:#F4845F
    style PUSH_REV fill:#FFF3CD,stroke:#F4845F
    style PUSH_SEG fill:#FFF3CD,stroke:#F4845F
    style MODAL8 fill:#FFE5E5,stroke:#F4845F
    style V3 fill:#1B4332,color:#fff
    style POSPONE fill:#e5e7eb,stroke:#9CA3AF
```

---

## 5. Diagrama — Flujo de aceptación de recomendación y creación de agenda

> Detalla exactamente qué pasa cuando el usuario acepta una recomendación post-diagnóstico.

```mermaid
flowchart TD
    V5([Vista 5\nAcción Recomendada]) --> INFO[Muestra:\n- Prioridad Alta / Media / Baja\n- Acción: 'Aplicar fungicida sistémico'\n- Tiempo: 'Hoy · próximas 48 horas'\n- Análisis costo-beneficio si aplica]

    INFO --> ACCION{¿Qué decide\nel usuario?}

    ACCION -- "✅ Agregar a mi agenda →" --> CREA3[⚙️ Sistema crea automáticamente\n3 actividades en la Agenda]
    ACCION -- "Rechazar recomendación" --> HOME[🏠 Home\nSin cambios en agenda]

    CREA3 --> ACT1[🔴 Actividad 1:\nPrimera aplicación de fungicida\nFecha: HOY · 19 jun 2026]
    CREA3 --> ACT2[🟡 Actividad 2:\nSeguimiento y revisión\nFecha: +7 días · 26 jun 2026]
    CREA3 --> ACT3[🟢 Actividad 3:\nNueva inspección con foto\nFecha: +14 días · 03 jul 2026]

    ACT1 --> MODAL5B[Modal 5b\n'¡Listo! Tu agenda fue actualizada'\nMuestra las 3 actividades creadas]
    ACT2 --> MODAL5B
    ACT3 --> MODAL5B

    MODAL5B --> BTN_AGENDA[Botón 'Ver mi agenda →']
    BTN_AGENDA --> V6[Vista 6\nAgenda]

    V6 --> CUMPLE{Conforme pasan\nlos días el usuario\nmarca actividades}
    CUMPLE -- "Marcar completada" --> COMPLETADA[✅ Actividad COMPLETADA\nRegistrada en historial\nIndice de salud +]
    CUMPLE -- "Posponer" --> POSPUESTA[⏸️ Actividad POSPUESTA\nReprogramada +1 día\nBadge gris en agenda]
    CUMPLE -- "Dejar pendiente" --> PENDIENTE[🟠 Actividad PENDIENTE\nBorde naranja en agenda\nNotificación recordatorio]

    style V5 fill:#FFE5E5,stroke:#F4845F
    style CREA3 fill:#D8F3DC,stroke:#2D6A4F
    style ACT1 fill:#FFE5E5,stroke:#cc0000
    style ACT2 fill:#FFF3CD,stroke:#F4845F
    style ACT3 fill:#D8F3DC,stroke:#1B4332
    style MODAL5B fill:#D8F3DC,stroke:#1B4332
    style COMPLETADA fill:#D8F3DC,stroke:#1B4332
    style POSPUESTA fill:#e5e7eb,stroke:#9CA3AF
    style HOME fill:#1B4332,color:#fff
```

---

## 6. Diagrama — Cálculo del indicador de salud del cultivo

> Muestra cómo se construye el porcentaje de salud que el usuario ve en Vista 2b.

```mermaid
flowchart LR
    FUENTES([Fuentes de datos\ndel sistema]) --> F1[🛡️ Enfermedades\ndetectadas\nCNN diagnósticos]
    FUENTES --> F2[✅ Cumplimiento\nde actividades\nAgenda completadas]
    FUENTES --> F3[👁️ Inspecciones\nrealizadas\nFotos enviadas]
    FUENTES --> F4[📈 Seguimientos\ncompletados\nReportes enviados]

    F1 --> PESO1[Peso: ~25%\nEjemplo: 90%\n'Sin patología activa']
    F2 --> PESO2[Peso: ~25%\nEjemplo: 80%\n'8 de 10 tareas']
    F3 --> PESO3[Peso: ~25%\nEjemplo: 75%\n'3 de 4 recorridos']
    F4 --> PESO4[Peso: ~25%\nEjemplo: 85%\n'2 de 2 reportes']

    PESO1 --> CALCULO[⚙️ Cálculo ponderado\npor el sistema]
    PESO2 --> CALCULO
    PESO3 --> CALCULO
    PESO4 --> CALCULO

    CALCULO --> RESULTADO[📊 Indicador de Salud\n85% · SALUD\nActualizado en cada sincronización]

    RESULTADO --> VISTA2B[Vista 2b\nEstado de mi Cultivo\nMuestra a usuario]

    style FUENTES fill:#D8F3DC,stroke:#2D6A4F
    style CALCULO fill:#D8F3DC,stroke:#2D6A4F
    style RESULTADO fill:#1B4332,color:#fff
    style VISTA2B fill:#1B4332,color:#fff
```

---

## 7. Diagrama — Estados de una actividad en el ciclo de vida

> Muestra todos los estados posibles de una actividad en la Agenda y cómo transita entre ellos.

```mermaid
stateDiagram-v2
    [*] --> Pendiente : Sistema crea actividad\n(manual o automática)

    Pendiente --> Completada : Usuario toca\n'Marcar completada'
    Pendiente --> Pospuesta : Usuario toca\n'Posponer para mañana'
    Pendiente --> Vencida : Fecha límite\npassó sin acción

    Pospuesta --> Pendiente : Sistema reprograma\n+1 día automáticamente
    Pospuesta --> Completada : Usuario completa\nen nueva fecha

    Vencida --> Pendiente : Usuario abre app\nbanner de recordatorio
    Vencida --> Completada : Usuario completa\nfuera de tiempo

    Completada --> [*] : Registrada en\nHistorial del Cultivo
```

---

## 8. Diagrama — Flujo de la pantalla Mi Cultivo · Ruta del Cultivo

> Detalla la interacción dentro de la Vista 2 y sus sub-secciones.

```mermaid
flowchart TD
    TAB([Tab 'Mi Cultivo'\nen navbar]) --> V2[Vista 2\nRuta del Cultivo]

    V2 --> HEADER[Header card:\nMaíz · Milpa Norte\n67% progreso · Semana 6 de 18\nBadges: 8 completadas / 3 pendientes / 1 pospuesta]

    V2 --> RUTA[Sección 'Ruta de inspección']
    RUTA --> ACORD_PASADO[Accordion 'Semanas 1–5'\nColapsado por defecto\nSemanas ya completadas]
    RUTA --> SEMANA_ACTUAL[Card activa con borde naranja\nHOY · SEMANA 6\nDesarrollo Vegetativo\nDescripción de actividad]
    RUTA --> ACORD_FUTURO[Accordion 'Semanas 7–18'\n'12 actividades pendientes'\nColapsado por defecto]

    SEMANA_ACTUAL --> BTN_INSP[Botón 'Realizar inspección ahora →']
    BTN_INSP --> V3[Vista 3\nDiagnóstico]

    ACORD_PASADO --> EXPANDIR_P{¿Toca para\nexpandir?}
    EXPANDIR_P -- SÍ --> LISTA_PASADAS[Lista de semanas 1–5\ncon estado completada/pospuesta]
    EXPANDIR_P -- NO --> ACORD_PASADO

    ACORD_FUTURO --> EXPANDIR_F{¿Toca para\nexpandir?}
    EXPANDIR_F -- SÍ --> LISTA_FUTURAS[Lista de semanas 7–18\nactividades próximas\nen modo lectura]
    EXPANDIR_F -- NO --> ACORD_FUTURO

    HEADER --> ESTADO[Toca indicador de progreso\no badge de salud]
    ESTADO --> V2B[Vista 2b\nEstado de mi Cultivo\n85% SALUD · 4 factores]

    style TAB fill:#D8F3DC,stroke:#1B4332
    style V2 fill:#1B4332,color:#fff
    style BTN_INSP fill:#F4845F,color:#fff
    style V2B fill:#2D6A4F,color:#fff
    style V3 fill:#2D6A4F,color:#fff
    style SEMANA_ACTUAL fill:#FFF3CD,stroke:#F4845F
```

---

## 9. Diagrama — Rol del microservicio CNN en el sistema

> Para claridad de implementación: qué envía la app, qué devuelve el CNN, cómo lo consume la UI.

```mermaid
sequenceDiagram
    actor U as Usuario
    participant V3 as Vista 3 (Diagnóstico)
    participant APP as App Android
    participant CNN as Microservicio CNN
    participant V4 as Vista 4 (Resultado)
    participant V5 as Vista 5 (Acción)

    U->>V3: Toma o elige foto
    U->>V3: Agrega descripción opcional
    U->>V3: Toca "Analizar foto →"

    V3->>APP: Prepara payload:\n{imagen: base64, descripcion: string,\ncultivo: 'Maíz', semana: 6}

    APP->>CNN: POST /diagnostico\n{imagen, metadata}
    Note over CNN: Procesa imagen\nIdentifica planta\nDetecta enfermedad

    CNN-->>APP: Respuesta:\n{planta: 'Zea mays',\nenfermedad: 'Tizón tardío',\nconfianza: 0.91,\nrecomienda_intervencion: true}

    APP->>V4: Renderiza resultado
    V4-->>U: Muestra card con diagnóstico\n+ confianza + estado

    U->>V4: Toca "Ver acción recomendada →"
    V4->>V5: Pasa contexto:\n{enfermedad, confianza, cultivo, semana}

    Note over V5: Microservicio de recomendaciones\ngenera acción en lenguaje natural\nMotor económico calcula costo-beneficio

    V5-->>U: Muestra:\n- Acción: 'Aplicar fungicida sistémico'\n- Prioridad: ALTA\n- Tiempo: 'Hoy · próximas 48 horas'\n- Análisis económico
```

---

## Vista 0 — Pantalla de Inicio (Home)

**Archivo sugerido:** `HomeProductorScreen`
**Punto de entrada:** Después de login exitoso con cultivo ya registrado.
**Si no tiene cultivo registrado** → redirige automáticamente a Vista 1.

```
┌─────────────────────────────────┐
│  [🌿 AgroGraph IA]        🔔   │  ← Header verde oscuro
│  Buenos días, [Nombre]          │
│  [Plan Free badge]              │
├─────────────────────────────────┤
│  ┌─────────────────────────┐    │
│  │ Mi cultivo · Maíz       │    │
│  │ Milpa Norte · 2.5 ha    │ 56%│  ← Círculo de progreso
│  │ Semana 6 de 18          │    │
│  │ ▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒      │    │  ← Barra de progreso verde
│  └─────────────────────────┘    │
├─────────────────────────────────┤
│  📅 PRÓXIMA ACTIVIDAD    [HOY]  │  ← Badge naranja
│  Inspección semanal del cultivo │
│  [🔍 Ir a inspección →]         │  ← Botón naranja sólido
├─────────────────────────────────┤
│  [📍 Mi ruta] [📋 Historial] [📆 Agenda] │  ← 3 accesos rápidos
├─────────────────────────────────┤
│  Últimos eventos                │
│  • Inspección realizada - sin patología  06 jun │
│  • Fertilización pendiente               10 jun │
└─────────────────────────────────┘
[Inicio●] [Diagnóstico] [Mi Cultivo] [Agenda] [Perfil]
```

**Estados del card "PRÓXIMA ACTIVIDAD":**
- Sin actividad hoy → "Sin actividades pendientes hoy 🎉"
- Actividad vencida → badge rojo "VENCIDA"

---

## Vista 1 — Registro de Cultivo

**Archivo sugerido:** `RegistroCultivoScreen`
**Sin navbar inferior** (flujo de onboarding).

```
┌─────────────────────────────────┐
│  [🌿 AgroGraph IA]              │  ← Header verde oscuro
│  Registra tu cultivo            │
├─────────────────────────────────┤
│  Con estos 3 datos generamos tu │
│  plan de actividades automát.   │
├─────────────────────────────────┤
│  1. ¿Qué vas a sembrar?         │
│  ┌──────┐ ┌──────┐ ┌──────┐    │
│  │ 🌽   │ │ 🫘   │ │ 🍅   │    │  ← Seleccionado: fondo verde + borde verde
│  │ Maíz │ │Frijol│ │Jitomate│  │
│  └──────┘ └──────┘ └──────┘    │
│  ┌──────┐ ┌──────┐ ┌──────┐    │
│  │ 🌶️   │ │ 🥔   │ │ 🎃   │    │
│  │Chile │ │ Papa │ │Calabaza│  │
│  └──────┘ └──────┘ └──────┘    │
├─────────────────────────────────┤
│  2. Fecha de siembra            │
│  [📅 03/01/2026          ▾]     │
│  Cosecha estimada: 15 ago 2026  │  ← Badge verde claro
├─────────────────────────────────┤
│  3. Superficie                  │
│  [Ej. 5      ] [Hectáreas ▾]   │
├─────────────────────────────────┤
│  ╔═══════════════════════════╗  │
│  ║ Tu plan generará 18       ║  │  ← Aparece cuando 3 campos completos
│  ║ semanas para Maíz.        ║  │
│  ║ Sin IA — plantillas de    ║  │
│  ║ agrónomos.                ║  │
│  ╚═══════════════════════════╝  │
│  [🌱 Generar mi plan →]         │  ← Naranja, deshabilitado hasta completar
└─────────────────────────────────┘
```

---

## Vista 2 — Mi Cultivo · Ruta del Cultivo

**Archivo sugerido:** `MiCultivoScreen`
**Tab activo:** Mi Cultivo

```
┌─────────────────────────────────┐
│  [🌿 AgroGraph IA]         🔔   │
│  ✕ Modo fuera de línea          │  ← Banner amarillo (condicional)
├─────────────────────────────────┤
│  Mi Cultivo · Maíz              │
│  Milpa Norte                    │
│  ○ 67%      Semana 6 de 18      │  ← Toca para ir a Vista 2b
│  📅 Cosecha: 15 ago 2026        │
│  [8 COMPL.] [3 PEND.] [1 POSP.] │
├─────────────────────────────────┤
│  RUTA DE INSPECCIÓN             │
│  [Semanas 1 - 5  ▾]             │  ← Accordion colapsado
│                                 │
│  ┌─────────────────────────┐    │
│  │ HOY · SEMANA 6       🌱 │    │  ← Borde naranja, card activa
│  │ Desarrollo Vegetativo   │    │
│  │ Monitorear aparición de │    │
│  │ hojas nuevas...         │    │
│  │ [Realizar inspección →] │    │  ← Botón naranja
│  └─────────────────────────┘    │
│                                 │
│  12 actividades pendientes ▾    │  ← Accordion semanas futuras
└─────────────────────────────────┘
[Inicio] [Diagnóstico] [Mi Cultivo●] [Agenda] [Perfil]
```

---

## Vista 2b — Estado de mi Cultivo

**Archivo sugerido:** `EstadoCultivoScreen`
**Acceso:** Desde indicador de progreso en Mi Cultivo o Home.

```
┌─────────────────────────────────┐
│  ← Estado de mi cultivo        │
├─────────────────────────────────┤
│         ╔═══════╗               │
│         ║  85%  ║               │  ← Círculo animado
│         ║ SALUD ║               │
│         ╚═══════╝               │
│      Maíz · Milpa Norte         │
│      📅 Semana 6                │
├─────────────────────────────────┤
│  🛡️ Enfermedades detectadas  90%│
│  ▓▓▓▓▓▓▓▓▓░  Sin patología activa│
│                                 │
│  ✅ Cumplimiento actividades  80%│
│  ▓▓▓▓▓▓▓▓░░  8 de 10 tareas    │
│                                 │
│  👁️ Inspecciones realizadas  75%│
│  ▓▓▓▓▓▓▓░░░  3 de 4 recorridos │
│                                 │
│  📈 Seguimientos completados 85%│
│  ▓▓▓▓▓▓▓▓▓░  2 de 2 reportes   │
├─────────────────────────────────┤
│  ℹ️ Indicadores actualizados     │
│  con las últimas sincronizaciones│
└─────────────────────────────────┘
[Inicio] [Diagnóstico] [Mi Cultivo●] [Agenda] [Perfil]
```

---

## Vista 3 — Diagnóstico (Cámara / Captura)

**Archivo sugerido:** `DiagnosticoScreen`
**Tab activo:** Diagnóstico

```
┌─────────────────────────────────┐
│  [🌿 AgroGraph IA]         🕐   │
│  ☰  Diagnóstico                 │
├─────────────────────────────────┤
│  [Analizar ●]  [Mis diagnósticos]│  ← Tabs internos
├─────────────────────────────────┤
│  ╔═══════════════════════════╗  │
│  ║ 🟠 INSPECCIÓN PENDIENTE   ║  │  ← Solo si viene de plan/notif
│  ║    · SEMANA 6             ║  │
│  ║ Maíz · Milpa Norte        ║  │
│  ║ Tu plan indica que es     ║  │
│  ║ momento de revisar.       ║  │
│  ║ [Ir a inspección →]       ║  │
│  ╚═══════════════════════════╝  │
│  — O REALIZA UN DIAGNÓSTICO LIBRE —│
│                                 │
│         📷                      │
│    Fotografía lo que ves        │
│  Cualquier planta o cultivo     │
├─────────────────────────────────┤
│  [   Tomar foto   ]             │  ← Naranja sólido
│  [  Elegir de galería  ]        │  ← Naranja outline
├─────────────────────────────────┤
│  Información adicional (opcional)│
│  [ Describe lo que observas 0/300]│
├─────────────────────────────────┤
│  [  Primero agrega una foto  ]  │  ← Deshabilitado / gris
└─────────────────────────────────┘
[Inicio] [Diagnóstico●] [Mi Cultivo] [Agenda] [Perfil]
```

---

## Vista 4 — Resultado del Diagnóstico

**Archivo sugerido:** `ResultadoDiagnosticoScreen`
**Acceso:** Automático tras procesar foto en Vista 3.

```
┌─────────────────────────────────┐
│  ← Resultado del diagnóstico   │
├─────────────────────────────────┤
│  [Miniatura foto tomada]        │  ← 180px altura
│                                 │
│  Planta identificada:           │
│  🌽 Maíz (Zea mays)            │
├─────────────────────────────────┤
│  DIAGNÓSTICO                    │
│                                 │
│  ╔═══════════════════════════╗  │  ← Card roja si enfermedad
│  ║ 🔴 Tizón tardío detectado ║  │
│  ║ Confianza: 91%            ║  │
│  ║ Intervención recomendada  ║  │
│  ╚═══════════════════════════╝  │
│                                 │  ← Card verde si sano
│  ╔═══════════════════════════╗  │
│  ║ ✅ Sin patología detectada║  │
│  ║ Confianza: 88%            ║  │
│  ╚═══════════════════════════╝  │
├─────────────────────────────────┤
│  [Ver acción recomendada →]     │  ← Naranja sólido
│  [Guardar en historial]         │  ← Verde outline
└─────────────────────────────────┘
```

**Si confianza < 60%:**
→ Banner amarillo + botón "Intentar de nuevo"

---

## Vista 5 — Acción Recomendada

**Archivo sugerido:** `AccionRecomendadaScreen`

```
┌─────────────────────────────────┐
│  ← Acción recomendada          │
│  Basado en: Tizón tardío        │
│  Maíz · Semana 6 · Milpa Norte  │
├─────────────────────────────────┤
│  ╔═══════════════════════════╗  │
│  ║ 🔴 PRIORIDAD ALTA         ║  │
│  ║                           ║  │
│  ║ Aplicar fungicida         ║  │
│  ║ sistémico                 ║  │
│  ║                           ║  │
│  ║ ⏱️ Hoy · próximas 48h     ║  │
│  ╚═══════════════════════════╝  │
│                                 │
│  ╔═══════════════════════════╗  │
│  ║ 💰 ¿Conviene económicamente?║ │  ← Solo si aplica por cultivo/región
│  ║ Costo tratamiento: ~$320  ║  │
│  ║ Pérdida sin trat: $1,800  ║  │
│  ║ ✅ Tratamiento recomendado ║  │
│  ╚═══════════════════════════╝  │
├─────────────────────────────────┤
│  [✅ Agregar a mi agenda →]     │  ← Naranja sólido
│  [Rechazar recomendación]       │  ← Texto gris
└─────────────────────────────────┘
```

---

## Vista 5b — Modal Confirmación de Agenda

**Tipo:** Modal sobre fondo oscurecido.

```
│  ░░░░░░░ fondo oscurecido ░░░░  │
│  ┌───────────────────────────┐  │
│  │  ✅ ¡Listo! Tu agenda fue │  │
│  │     actualizada           │  │
│  │  3 actividades creadas:   │  │
│  │  🔴 Primera aplicación    │  │
│  │     fungicida · HOY       │  │
│  │  🟡 Seguimiento y revisión│  │
│  │     26 jun 2026           │  │
│  │  🟢 Nueva inspección foto │  │
│  │     03 jul 2026           │  │
│  │  Recibirás recordatorios. │  │
│  │  [Ver mi agenda →]        │  │  ← Verde oscuro sólido
│  └───────────────────────────┘  │
```

---

## Vista 6 — Agenda

**Archivo sugerido:** `AgendaScreen`
**Tab activo:** Agenda

```
┌─────────────────────────────────┐
│  [🌿 AgroGraph IA]         🔔   │
│  Mi Agenda                      │
├─────────────────────────────────┤
│  [◀ Jun 2026 ▶]                 │
│  L  M  X  J  V  S  D           │
│  ...  19● 20 21 22 ...         │  ← Punto naranja = actividad
├─────────────────────────────────┤
│  HOY · 19 junio                 │
│  ┌─────────────────────────┐    │
│  │ 🔴 Primera aplicación   │    │
│  │    de fungicida         │    │
│  │ Maíz · Milpa Norte      │    │
│  │ [Marcar completada]     │    │
│  └─────────────────────────┘    │
│  PRÓXIMOS                       │
│  ┌─────────────────────────┐    │
│  │ 🟡 26 jun · Seguimiento │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ 🟢 03 jul · Inspección  │    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘
[Inicio] [Diagnóstico] [Mi Cultivo] [Agenda●] [Perfil]
```

---

## Vista 7 — Historial del Cultivo

**Archivo sugerido:** `HistorialCultivoScreen`

```
┌─────────────────────────────────┐
│  ← Mi historial                │
│  Generado automáticamente.     │
├─────────────────────────────────┤
│  🟢 Siembra                15 Mar│
│  Maíz H-59 · 2.5 ha · Milpa Norte│
│  👁️ Inspección sin patología  22 Mar│
│  💧 Fertilización            05 Abr│
│  👁️ Inspección semana 5     19 Abr│
│  🔴 Detección de enfermedad  25 Abr│  ← Card fondo rojo suave
│     Tizón tardío · 91% · intervención│
│  🟠 Tratamiento aplicado    26 Abr│
│     Metalaxil 1.5 ml/L            │
│  📈 Mejora observada        03 May│
│  ✅ Seguimiento completado  10 May│
│  👁️ Inspección semana 10   17 May│
│  ⏸️ Fertilización pospuesta  06 Jun│  ← Card gris
└─────────────────────────────────┘
[Inicio] [Diagnóstico] [Mi Cultivo●] [Agenda] [Perfil]
```

---

## Vista 8 — Modal de Inspección Programada

**Tipo:** Modal / bottom sheet al abrir app con inspección pendiente.

```
│  ░░░░░░░ fondo oscurecido ░░░░  │
│  ┌───────────────────────────┐  │
│  │         🌱                │  │
│  │  Es momento de            │  │
│  │  inspeccionar             │  │
│  │  Semana 6 · Inspección    │  │
│  │  programada               │  │
│  │  Toma una foto de tus     │  │
│  │  plantas para que el      │  │
│  │  modelo de IA analice.    │  │
│  │  [Hoy · 19 jun 2026]      │  │  ← Badge verde claro
│  │  [Ir a diagnóstico →]     │  │  ← Naranja sólido
│  │  [Posponer para mañana]   │  │  ← Outline
│  └───────────────────────────┘  │
```

---

## Reglas de navegación

1. **Header siempre muestra "AgroGraph IA"** en todas las pantallas.
2. **Tab activo** resaltado en verde oscuro `#1B4332`.
3. Subpantallas (2b, 4, 5, 5b, 7, 8) heredan el tab activo de su pantalla padre.
4. **CTA principal**: siempre naranja sólido `#F4845F` con texto blanco.
5. **Botones secundarios**: outline naranja o verde.
6. Banner contextual en Vista 3 se muestra **siempre** si el usuario viene de inspección programada.
7. Flujo CNN: foto → spinner "Analizando tu cultivo..." → resultado. La app solo consume la respuesta del microservicio existente.

---

## Componentes reutilizables

| Componente | Usado en |
|---|---|
| `CultivoBadge` | Home, Mi Cultivo, Historial |
| `ProgresoCircular` | Home, Mi Cultivo, Estado 2b |
| `BarraProgresoLineal` | Home, Estado 2b |
| `ActividadCard` | Agenda, Mi Cultivo |
| `EventoHistorial` | Historial |
| `ModalBottomSheet` | Modal 8, Modal 5b |
| `BannerContextual` | Vista 3 (inspección pendiente) |
| `SelectorCultivo` | Registro de cultivo |
| `IndicadorFactor` | Estado 2b |

---

*AgroGraph-MAS · Perfil Productor Guiado · Flujo de vistas para maquetado*