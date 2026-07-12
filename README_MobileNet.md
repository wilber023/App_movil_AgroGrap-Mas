# Cómo funciona MobileNet (V3-Large) — Guía para FitoNet

> Explicación del backbone de la CNN del sistema: **qué es MobileNet, por qué es
> ligero, cómo está construido y por qué lo usamos para el modo offline on-device.**
> Documento de apoyo a `DOCUMENTACION_TECNICA_FitoNet_CNN.md`.

---

## 1. ¿Qué es MobileNet y para qué sirve?

**MobileNet** es una familia de redes neuronales convolucionales (CNN) diseñada por Google para correr en **dispositivos con recursos limitados** (teléfonos, sistemas embebidos). Su objetivo es dar buena precisión **con muy pocos parámetros y pocas operaciones**, de modo que la inferencia sea rápida y el modelo quepa en un móvil.

En FitoNet la usamos como **extractor de características** de la foto de la hoja: MobileNet transforma la imagen en un vector, y encima le ponemos una **cabeza** que decide entre las 33 clases (`Cultivo___Enfermedad`).

**Versiones de la familia:**

| Versión | Aporte principal |
|---|---|
| MobileNetV1 (2017) | Convoluciones **separables en profundidad** (la idea base). |
| MobileNetV2 (2018) | Bloques **inverted residual** + **linear bottleneck**. |
| **MobileNetV3 (2019)** | **Squeeze-and-Excitation**, activación **h-swish**, arquitectura afinada por búsqueda automática (NAS). ← *la que usamos.* |

---

## 2. La idea central: convolución separable en profundidad

Aquí está el 90 % del "por qué es ligero". Comparemos una convolución normal con la de MobileNet.

### Convolución estándar

Una convolución clásica hace **dos cosas a la vez** en un solo paso: mezcla información **espacial** (los vecinos de cada píxel) **y** entre **canales** (los distintos mapas de color/características). Eso cuesta muchas multiplicaciones.

> Costo aproximado ∝ `Dk · Dk · M · N · Df · Df`
> (tamaño de filtro `Dk`, canales de entrada `M`, canales de salida `N`, tamaño del mapa `Df`).

### Convolución separable en profundidad (MobileNet)

MobileNet **separa** ese trabajo en dos pasos más baratos:

1. **Depthwise:** aplica **un filtro por canal** (solo mezcla espacial, canal por canal). No combina canales.
2. **Pointwise (1×1):** una convolución `1×1` que **combina los canales** entre sí.

> Costo aproximado ∝ `Dk·Dk·M·Df·Df  +  M·N·Df·Df`

**El ahorro:** dividir el trabajo reduce el cómputo por un factor de aproximadamente **`1/N + 1/(Dk²)`**. Para filtros de 3×3, eso es **entre 8 y 9 veces menos operaciones** que una convolución normal, con una pérdida de precisión pequeña.

```
Convolución normal:        [ mezcla espacial + canales ]  (caro)

Separable en profundidad:  [ depthwise: espacial ] → [ pointwise 1×1: canales ]  (barato)
```

Esta es la razón por la que MobileNet puede correr en un teléfono donde una CNN clásica sería demasiado pesada.

---

## 3. Bloques de MobileNetV2: *inverted residual* + *linear bottleneck*

MobileNetV2 introdujo el bloque que MobileNetV3 sigue usando:

- **Inverted residual (residual invertido):** a diferencia de un ResNet clásico (que comprime → procesa → expande), aquí se hace **expandir → procesar (depthwise) → comprimir**. El bloque trabaja "ancho" en el medio y "estrecho" en los extremos.
- **Linear bottleneck:** en la salida comprimida **no** se aplica activación no lineal (ReLU), porque aplicarla en un espacio de pocas dimensiones destruye información. Se deja lineal.
- **Conexión residual (atajo):** cuando entrada y salida tienen la misma forma, se suman (como en ResNet), lo que facilita entrenar redes profundas.

Intuición: expandir da "espacio" para que la convolución depthwise trabaje, y comprimir al final mantiene el modelo pequeño.

---

## 4. Lo nuevo de MobileNetV3 (la versión que usamos)

MobileNetV3 toma el bloque anterior y le añade tres mejoras:

### 4.1 Squeeze-and-Excitation (SE) — "atención" por canal
Un pequeño submódulo que aprende **qué canales son más importantes** para cada imagen y los **realza**, atenuando los menos útiles. Es como un mecanismo de atención barato sobre los canales: mejora la precisión con muy poco costo extra.

### 4.2 Activación h-swish (hard-swish)
Reemplaza a ReLU en las capas profundas por una versión **eficiente** de la función *swish*:

> `h-swish(x) = x · ReLU6(x + 3) / 6`

Da mejores resultados que ReLU pero, al usar `ReLU6` en vez de una sigmoide/exponencial, es **rápida de calcular** (ideal para móvil).

### 4.3 Arquitectura afinada por NAS
La estructura (cuántos bloques, cuántos canales, dónde poner SE) se optimizó con **búsqueda automática de arquitectura** (Neural Architecture Search) y ajustes manuales (NetAdapt), buscando el mejor equilibrio **precisión / latencia real en teléfono**. Existen dos tamaños:

- **MobileNetV3-Large** — más preciso (← el que usamos en FitoNet).
- **MobileNetV3-Small** — aún más liviano, para dispositivos muy limitados.

---

## 5. Cómo lo usamos en FitoNet (transfer learning)

No entrenamos MobileNet desde cero: partimos de pesos **preentrenados en ImageNet** (millones de imágenes) y lo adaptamos a nuestras hojas. Esto es **transfer learning** y funciona porque las primeras capas ya saben detectar bordes, texturas y patrones útiles para cualquier imagen.

### 5.1 La cabeza que le añadimos

Quitamos la cabeza original de 1000 clases de ImageNet y ponemos la nuestra:

```
[ Backbone MobileNetV3-Large preentrenado ]  → vector de 960 características
        │
   Linear(960 → 1280)
   Hardswish
   Dropout(0.4)            ← regularización (evita sobreajuste)
   Linear(1280 → 33)       ← una salida por clase
        │
   33 logits → argmax → clase predicha
```

### 5.2 Entrenamiento en dos fases

1. **Fase 1 — cabeza:** congelamos el backbone y entrenamos solo la cabeza. La red aprende a usar las características de ImageNet para nuestras 33 clases sin dañar lo ya aprendido.
2. **Fase 2 — fine-tuning:** descongelamos todo y ajustamos con un *learning rate* muy bajo, para afinar el backbone a las hojas sin "olvidar" ImageNet.

### 5.3 Entrada y salida

| | |
|---|---|
| **Entrada** | Imagen 224×224, RGB, normalizada (mean/std de ImageNet), formato NCHW `(1,3,224,224)`. |
| **Salida** | 33 logits; la clase es el `argmax`. |
| **Parámetros** | ≈5.4 millones. |

---

## 6. Por qué MobileNet para el modo offline (y no EfficientNet-B4)

El sistema debe funcionar **sin conexión, dentro del teléfono**. Ahí el tamaño y la velocidad del modelo son decisivos:

| | EfficientNet-B4 | **MobileNetV3-Large** |
|---|---|---|
| Parámetros | ≈19 M | **≈5.4 M** |
| Entrada | 380×380 | **224×224** |
| Enfoque | Máxima precisión | **Eficiencia on-device** |
| Modelo TFLite | Grande | **~17 MB (fp32), ~5–6 MB (int8)** |
| Uso en el proyecto | Versión previa | **Versión actual (offline)** |

MobileNetV3 sacrifica algo de capacidad teórica, pero:
- Ocupa **mucho menos** en el teléfono.
- Corre **más rápido** y gasta **menos batería**.
- Aun así logró **97.7 % de accuracy** en test para nuestras 33 clases.

Para el **modo online** (con cobertura), donde el modelo corre en la nube y el tamaño no importa, se podría usar un backbone más grande; en el móvil, MobileNet es la elección correcta.

---

## 7. De MobileNet a TFLite (despliegue)

El modelo entrenado en PyTorch se convierte a **TFLite** (con `litert-torch`) para ejecutarse on-device:

```
best.pth (PyTorch)  ──litert-torch──▶  fitonet_mobilenetv3_fp32.tflite  ──▶  app móvil (offline)
```

La app carga el `.tflite` + `fitonet_metadata.json` y **debe preprocesar la foto igual que en el entrenamiento** (224×224, RGB, normalización ImageNet, NCHW). Ver detalles en `DOCUMENTACION_TECNICA_FitoNet_CNN.md`, sección 8.

---

## 8. Resumen en una frase

> **MobileNetV3-Large logra buena precisión con pocas operaciones al reemplazar las convoluciones normales por convoluciones separables en profundidad (depthwise + pointwise), organizarlas en bloques residuales invertidos, y añadir atención por canal (SE) y la activación eficiente h-swish; por eso cabe y corre en un teléfono, que es justo lo que necesita el modo offline de FitoNet.**

---

## Referencias

- Howard et al. (2017), *MobileNets: Efficient Convolutional Neural Networks for Mobile Vision Applications*.
- Sandler et al. (2018), *MobileNetV2: Inverted Residuals and Linear Bottlenecks*.
- Howard et al. (2019), *Searching for MobileNetV3*.
- Documentación de torchvision: `torchvision.models.mobilenet_v3_large`.
- Google AI Edge — LiteRT / conversión PyTorch → TFLite.
