# Fix — Tarjeta "Aprende algo nuevo" muestra el campo equivocado

## El problema
La tarjeta muestra texto de **fusión CNN+NLP** ("El texto no aporta señales
sobre esta enfermedad. Confianza sin cambios (0.97)") en vez de la enseñanza
pedagógica que genera el LLM para el rol aprendiz.

## Causa (ya confirmada, con el flujo completo rastreado)
El backend **ya envía correctamente** el campo `aprendizaje` dentro de
`respuesta` en la respuesta de `POST /api/v1/consultar` — lo genera
`generador.responder()` y viaja sin pérdida hasta el JSON final. **No hay que
tocar nada en el backend.**

El bug es 100% del lado Flutter: la tarjeta está enganchada a
`llm.explicacion`, que es un campo *distinto* — la explicación técnica del
módulo de fusión (por qué subió/bajó la confianza), no la enseñanza del LLM.
Ese campo (`explicacion`) sale de `json['diagnostico']['explicacion']`.
El campo que sí hay que usar (`aprendizaje`) sale de
`json['respuesta']['aprendizaje']` — **es una ruta distinta dentro del mismo
JSON**, ese es el detalle a no pasar por alto.

## Contrato del backend (referencia)
```json
{
  "diagnostico": { "...": "...", "explicacion": "..." },   // fusión CNN+NLP — NO usar para esta tarjeta
  "respuesta": {
    "diagnostico": "...", "tratamiento": "...", "prevencion": "...",
    "aprendizaje": "Sabías que...\nQué puedes hacer con esto: ...",  // <-- este es el campo correcto
    "fuentes": ["..."], "texto": "..."
  }
}
```

## Los 4 archivos a tocar (en este orden)

### 1. `lib/features/agricultor/diagnosis/domain/entities/llm_response_entity.dart`
Agregar el campo `aprendizaje` (no quitar `explicacion`, sigue usándose en
otro lado):
```dart
class LlmResponseEntity {
  final String diagnostico;
  final String tratamiento;
  final String prevencion;
  final String aprendizaje;          // <-- nuevo
  final List<String> fuentes;
  ...

  const LlmResponseEntity({
    required this.diagnostico,
    required this.tratamiento,
    required this.prevencion,
    required this.aprendizaje,        // <-- nuevo
    ...
  });

  Map<String, dynamic> toJson() => {
        ...
        'aprendizaje': aprendizaje,   // <-- nuevo
        ...
      };

  factory LlmResponseEntity.fromJson(Map<String, dynamic> json) =>
      LlmResponseEntity(
        ...
        aprendizaje: json['aprendizaje'] as String? ?? '',  // <-- nuevo
        ...
      );
}
```

### 2. `lib/features/agricultor/diagnosis/data/datasources/llm_diagnosis_datasource.dart`
En `_parse()` (línea ~74), agregar el nuevo campo leyéndolo de **`respuesta`**
(no de `diag` — ese es el error fácil de cometer aquí):
```dart
return LlmResponseEntity(
  diagnostico: diagnostico.isNotEmpty ? diagnostico : texto,
  tratamiento: tratamiento,
  prevencion: prevencion,
  aprendizaje: respuesta['aprendizaje'] as String? ?? '',   // <-- nuevo, de "respuesta"
  fuentes: fuentes,
  confianzaAjustada: (diag['confianza_ajustada'] as num?)?.toDouble() ?? 0.0,
  estado: diag['estado'] as String? ?? '',
  explicacion: diag['explicacion'] as String? ?? '',        // se queda igual
  ...
);
```

### 3. `lib/features/aprendiz/diagnostico/presentation/mappers/diagnosis_result_mapper.dart:54`
Cambiar la fuente de `funFact` (esto es lo que alimenta
`DiagnosisFunFactCard`):
```dart
// antes:
funFact: llm.explicacion.trim().isEmpty ? null : llm.explicacion.trim(),
// despues:
funFact: llm.aprendizaje.trim().isEmpty ? null : llm.aprendizaje.trim(),
```

### 4. `lib/features/aprendiz/inicio/data/repositories/aprendiz_home_repository_impl.dart:134`
Mismo cambio, para la tarjeta de "Aprende algo nuevo" que aparece en el
resumen de Inicio:
```dart
// antes:
funFact: latestDiagnosis?.llmResponse?.explicacion.trim().isNotEmpty == true
    ? latestDiagnosis!.llmResponse!.explicacion.trim()
    : null,
// despues:
funFact: latestDiagnosis?.llmResponse?.aprendizaje.trim().isNotEmpty == true
    ? latestDiagnosis!.llmResponse!.aprendizaje.trim()
    : null,
```

## Qué NO tocar
- No renombrar ni quitar `explicacion` — es un campo real (fusión CNN+NLP),
  puede usarse en otro lugar en el futuro (hoy solo alimentaba, por error,
  esta tarjeta).
- No hace falta ningún cambio en el backend/GPU — ya envía todo correcto.

## Cómo verificar que quedó
Después de aplicar, hacer un diagnóstico como aprendiz y abrir "Aprende algo
nuevo": debe mostrar "¿Sabías que...? [causa de la enfermedad]" seguido de
"Qué puedes hacer con esto: [acción concreta]" — nunca texto sobre
"confianza" o "señales del texto".
