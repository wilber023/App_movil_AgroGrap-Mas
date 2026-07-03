// Base de conocimiento agrícola indexada por etiqueta CNN exacta.
// Fuente de verdad: las 50 clases del modelo best.pth (class_mapping extraído).

class DiseaseInfo {
  final String cropName;
  final String diseaseName;
  final String scientificName;
  final String severity;
  final List<String> whatIs;
  final List<String> whatToDo;
  final String ifNoAction;

  const DiseaseInfo({
    required this.cropName,
    required this.diseaseName,
    required this.scientificName,
    required this.severity,
    this.whatIs = const [],
    this.whatToDo = const [],
    this.ifNoAction = '',
  });
}

class AgriculturalKnowledgeBase {
  AgriculturalKnowledgeBase._();

  static DiseaseInfo lookup(String cnnLabel) =>
      _db[cnnLabel] ?? _fallback(cnnLabel);

  static DiseaseInfo _fallback(String label) {
    final parts = label.replaceAll('___', '|').replaceAll('_', ' ').split('|');
    final crop = parts.length > 1 ? parts[0].trim() : 'Cultivo';
    final disease = parts.length > 1 ? parts[1].trim() : label.replaceAll('_', ' ');
    return DiseaseInfo(
      cropName: crop,
      diseaseName: disease,
      scientificName: '',
      severity: disease.toLowerCase().contains('healthy') ||
              disease.toLowerCase().contains('healthy') ||
              disease.toLowerCase().contains('buenos')
          ? 'Saludable'
          : 'Moderada',
      whatIs: ['Enfermedad detectada por el modelo CNN. Consulta a un agrónomo local para confirmación.'],
      whatToDo: ['Observa el cultivo de cerca e identifica síntomas adicionales. Consulta a un especialista.'],
      ifNoAction: 'La enfermedad puede progresar sin diagnóstico confirmado.',
    );
  }

  static const Map<String, DiseaseInfo> _db = {

    // ── Manzana ──────────────────────────────────────────────────────────────
    'Apple___Apple_scab': DiseaseInfo(
      cropName: 'Manzana',
      diseaseName: 'Sarna del manzano',
      scientificName: 'Venturia inaequalis',
      severity: 'Moderada',
      whatIs: ['Hongo que produce manchas velludas de color oliva en hojas y frutos. Se propaga por ascosporas durante lluvias de primavera.'],
      whatToDo: ['Aplica difenoconazol (25% a 0.5 ml/L) preventivamente desde brotación. Recoge y destruye las hojas caídas.'],
      ifNoAction: 'Sin control puede infectar el 80% de los frutos haciéndolos no comerciales.',
    ),
    'Apple___Black_rot': DiseaseInfo(
      cropName: 'Manzana',
      diseaseName: 'Podredumbre negra',
      scientificName: 'Botryosphaeria obtusa',
      severity: 'Critica',
      whatIs: ['Hongo que pudre frutos, causa manchas en hojas y cancros en ramas. Sobrevive en madera muerta y frutos momificados.'],
      whatToDo: ['Elimina frutos momificados y ramas con cancros. Aplica fungicida cúprico (3 g/L) tras la caída de pétalos.'],
      ifNoAction: 'Puede destruir la cosecha completa y debilitar el árbol para el siguiente ciclo.',
    ),
    'Apple___Cedar_apple_rust': DiseaseInfo(
      cropName: 'Manzana',
      diseaseName: 'Roya del manzano-cedro',
      scientificName: 'Gymnosporangium juniperi-virginianae',
      severity: 'Moderada',
      whatIs: ['Hongo con ciclo alternante entre manzano y cedro/enebro. Produce manchas anaranjadas brillantes en hojas de manzano.'],
      whatToDo: ['Elimina cedros o enebros cercanos si es posible. Aplica miclobutanil (0.4 ml/L) desde brotación.'],
      ifNoAction: 'Defoliación progresiva que reduce vigor y producción de frutos.',
    ),
    'Apple___healthy': DiseaseInfo(
      cropName: 'Manzana',
      diseaseName: 'Planta sana',
      scientificName: '',
      severity: 'Saludable',
      whatIs: ['El modelo no detecta signos de enfermedad activa en la imagen.'],
      whatToDo: ['Continúa con el monitoreo semanal. Mantén podas preventivas en invierno.'],
    ),

    // ── Citrus (sin prefijo de cultivo) ──────────────────────────────────────
    'Black spot': DiseaseInfo(
      cropName: 'Naranja',
      diseaseName: 'Mancha negra cítrica',
      scientificName: 'Phyllosticta citricarpa',
      severity: 'Moderada',
      whatIs: ['Hongo que produce manchas negras hundidas en la piel del fruto. No destruye el fruto internamente pero lo hace no comercializable.'],
      whatToDo: ['Aplica fungicida cúprico (3 g/L) tras la caída de pétalos y repite cada 4–6 semanas. Elimina frutos caídos.'],
      ifNoAction: 'Pérdida de valor comercial del 30–50% de la cosecha.',
    ),
    'Canker': DiseaseInfo(
      cropName: 'Naranja',
      diseaseName: 'Cancro cítrico',
      scientificName: 'Xanthomonas citri pv. citri',
      severity: 'Critica',
      whatIs: ['Bacteria que produce lesiones corchosas elevadas en hojas, ramas y frutos. Extremadamente contagiosa y difícil de erradicar.'],
      whatToDo: ['Elimina y destruye partes afectadas. Desinfecta herramientas con lejía al 10%. Aplica cobre bactericida preventivo.'],
      ifNoAction: 'La bacteria puede extenderse a toda la plantación y a parcelas vecinas, con pérdidas permanentes.',
    ),
    'Greening': DiseaseInfo(
      cropName: 'Naranja',
      diseaseName: 'HLB (Huanglongbing)',
      scientificName: 'Candidatus Liberibacter asiaticus',
      severity: 'Critica',
      whatIs: ['La enfermedad más destructiva de los cítricos a nivel mundial. Bacteria transmitida por insecto psílido que destruye el floema del árbol.'],
      whatToDo: ['No tiene cura. Elimina árboles infectados de inmediato para proteger la plantación. Controla el insecto vector con insecticidas.'],
      ifNoAction: 'El árbol muere en 3–5 años. La bacteria se propaga a todos los árboles cercanos.',
    ),
    'Melanose': DiseaseInfo(
      cropName: 'Naranja',
      diseaseName: 'Melanosis de cítricos',
      scientificName: 'Diaporthe citri',
      severity: 'Leve',
      whatIs: ['Hongo que produce manchas corchosas marrones en piel de frutos y hojas jóvenes. Afecta apariencia pero no calidad interna.'],
      whatToDo: ['Elimina ramas secas que son fuente de inóculo. Aplica cobre (3 g/L) tras la caída de pétalos.'],
      ifNoAction: 'Reduce el valor comercial del fruto hasta un 30% sin afectar la producción volumétrica.',
    ),

    // ── Mora (Blueberry) ────────────────────────────────────────────────────
    'Blueberry___healthy': DiseaseInfo(
      cropName: 'Mora',
      diseaseName: 'Planta sana',
      scientificName: '',
      severity: 'Saludable',
      whatIs: ['El modelo no detecta signos de enfermedad activa en la imagen.'],
      whatToDo: ['Mantén monitoreo regular. Asegura riego y pH del suelo adecuado (4.5–5.5 para blueberry).'],
    ),

    // ── Calabaza ─────────────────────────────────────────────────────────────
    'Calabaza_Bacterial Leaf Spot': DiseaseInfo(
      cropName: 'Calabaza',
      diseaseName: 'Mancha bacteriana',
      scientificName: 'Xanthomonas cucurbitae',
      severity: 'Moderada',
      whatIs: ['Bacteria que produce manchas angulares acuosas en hojas que se vuelven necróticas. Se propaga por salpique de agua y herramientas.'],
      whatToDo: ['Aplica cobre bactericida (3 g/L) cada 7–10 días. Evita el riego por aspersión. Mejora la aireación entre plantas.'],
      ifNoAction: 'Defoliación progresiva que reduce el rendimiento de frutos un 30–50%.',
    ),
    'Calabaza_Downy Mildew': DiseaseInfo(
      cropName: 'Calabaza',
      diseaseName: 'Mildiu velloso',
      scientificName: 'Pseudoperonospora cubensis',
      severity: 'Moderada',
      whatIs: ['Oomiceto que produce manchas angulares amarillas en el haz y moho gris-violáceo en el envés. Requiere alta humedad y temperatura de 15–22 °C.'],
      whatToDo: ['Aplica fosetil-Al (80% a 2.5 g/L) o mancozeb preventivo. Mejora drenaje y ventilación. Riega en la mañana.'],
      ifNoAction: 'Puede defoliar completamente la planta en 2 semanas con clima húmedo.',
    ),
    'Calabaza_Healthy Leaf': DiseaseInfo(
      cropName: 'Calabaza',
      diseaseName: 'Planta sana',
      scientificName: '',
      severity: 'Saludable',
      whatIs: ['El modelo no detecta signos de enfermedad activa en la imagen.'],
      whatToDo: ['Continúa el monitoreo. Mantén riego por goteo y fertilización balanceada.'],
    ),
    'Calabaza_Mosaic Disease': DiseaseInfo(
      cropName: 'Calabaza',
      diseaseName: 'Virus del mosaico',
      scientificName: 'Watermelon mosaic virus',
      severity: 'Leve',
      whatIs: ['Virus transmitido por áfidos que produce mosaico verde claro-oscuro y deformación de hojas. No tiene cura directa.'],
      whatToDo: ['Controla los áfidos con aceite de neem (5 ml/L). Elimina plantas muy afectadas. Usa malla antiáfidos si es posible.'],
      ifNoAction: 'El virus puede propagarse a toda la parcela a través de los áfidos.',
    ),
    'Calabaza_Powdery_Mildew': DiseaseInfo(
      cropName: 'Calabaza',
      diseaseName: 'Mildiu polvoroso',
      scientificName: 'Podosphaera xanthii',
      severity: 'Moderada',
      whatIs: ['Hongo superficial que cubre la epidermis foliar con micelio blanco en polvo. Avanza rápido en ambientes cálidos y secos con humedad nocturna alta.'],
      whatToDo: ['Aplica azufre mojable (2 g/L) cada 10 días. Elimina hojas muy afectadas. Mejora la ventilación del cultivo.'],
      ifNoAction: 'Pérdida de capacidad fotosintética. Reducción de cosecha estimada en 40–60% en 3 semanas.',
    ),

    // ── Cereza ───────────────────────────────────────────────────────────────
    'Cherry_(including_sour)___Powdery_mildew': DiseaseInfo(
      cropName: 'Cereza',
      diseaseName: 'Oídio del cerezo',
      scientificName: 'Podosphaera clandestina',
      severity: 'Moderada',
      whatIs: ['Hongo que produce polvo blanco en hojas y brotes jóvenes. Clima seco con noches frescas lo favorece. Debilita el desarrollo de frutos.'],
      whatToDo: ['Aplica azufre mojable (3 g/L) o miclobutanil (0.4 ml/L) cada 10–14 días desde brotación. Mejora la aireación.'],
      ifNoAction: 'Deforma frutos y reduce rendimiento un 25–40%. Debilita el árbol para el siguiente año.',
    ),
    'Cherry_(including_sour)___healthy': DiseaseInfo(
      cropName: 'Cereza',
      diseaseName: 'Planta sana',
      scientificName: '',
      severity: 'Saludable',
      whatIs: ['El modelo no detecta signos de enfermedad activa en la imagen.'],
      whatToDo: ['Monitoreo semanal en floración. Poda preventiva en invierno para mejorar aireación.'],
    ),

    // ── Naranja / Citrus ─────────────────────────────────────────────────────
    'Citrus_Healthy': DiseaseInfo(
      cropName: 'Naranja',
      diseaseName: 'Planta sana',
      scientificName: '',
      severity: 'Saludable',
      whatIs: ['El modelo no detecta signos de enfermedad activa en la imagen.'],
      whatToDo: ['Fertilización adecuada y manejo de riego óptimo para árboles vigorosos.'],
    ),
    'Orange___Haunglongbing_(Citrus_greening)': DiseaseInfo(
      cropName: 'Naranja',
      diseaseName: 'HLB (Huanglongbing)',
      scientificName: 'Candidatus Liberibacter asiaticus',
      severity: 'Critica',
      whatIs: ['La enfermedad más destructiva de los cítricos. Bacteria transmitida por psílido asiático. Produce amarillamiento asimétrico ("blotchy mottle") e incompletamente verde en frutos.'],
      whatToDo: ['No tiene cura. Elimina árboles infectados inmediatamente. Aplica insecticidas sistémicos (imidacloprid) para controlar el psílido vector.'],
      ifNoAction: 'El árbol muere lentamente en 3–5 años y contagia a árboles sanos circundantes.',
    ),

    // ── Maíz ─────────────────────────────────────────────────────────────────
    'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot': DiseaseInfo(
      cropName: 'Maíz',
      diseaseName: 'Mancha gris (Cercospora)',
      scientificName: 'Cercospora zeae-maydis',
      severity: 'Moderada',
      whatIs: ['Hongo que produce lesiones rectangulares grises limitadas por las nervaduras. Alta humedad y temperatura de 25–30 °C lo favorecen.'],
      whatToDo: ['Aplica triazol (propiconazol 25% a 1 ml/L) al detectar primeras lesiones. Usa híbridos tolerantes en el siguiente ciclo.'],
      ifNoAction: 'Pérdida de rendimiento del 30–50% si afecta la hoja bandera antes del espigamiento.',
    ),
    'Corn_(maize)___Common_rust_': DiseaseInfo(
      cropName: 'Maíz',
      diseaseName: 'Roya común',
      scientificName: 'Puccinia sorghi',
      severity: 'Leve',
      whatIs: ['Hongo que produce pústulas rojizas circulares en ambas caras de la hoja. Frecuente en zonas de altitud media-alta. Las uredosporas se dispersan por viento.'],
      whatToDo: ['En infecciones leves, el cultivo generalmente tolera la roya. Si hay alta densidad de pústulas, aplica triazol preventivo.'],
      ifNoAction: 'En variedades susceptibles puede causar pérdidas del 20–30% en rendimiento.',
    ),
    'Corn_(maize)___Northern_Leaf_Blight': DiseaseInfo(
      cropName: 'Maíz',
      diseaseName: 'Tizón foliar del norte',
      scientificName: 'Exserohilum turcicum',
      severity: 'Moderada',
      whatIs: ['Hongo que produce lesiones alargadas en forma de cigarro, de color gris-verdoso. Temperatura de 18–27 °C y alta humedad lo favorecen.'],
      whatToDo: ['Aplica fungicida triazol (propiconazol 25% a 1 ml/L) al detectar primeros síntomas. Usa híbridos resistentes.'],
      ifNoAction: 'Pérdida de hasta el 50% del rendimiento si el tizón afecta la hoja bandera antes del espigamiento.',
    ),
    'Corn_(maize)___healthy': DiseaseInfo(
      cropName: 'Maíz',
      diseaseName: 'Planta sana',
      scientificName: '',
      severity: 'Saludable',
      whatIs: ['El modelo no detecta signos de enfermedad activa en la imagen.'],
      whatToDo: ['Continúa el monitoreo. Asegura riego y nutrición adecuada en etapas críticas.'],
    ),

    // ── Frijol ───────────────────────────────────────────────────────────────
    'Frijol_Buenos': DiseaseInfo(
      cropName: 'Frijol',
      diseaseName: 'Grano sano',
      scientificName: '',
      severity: 'Saludable',
      whatIs: ['El modelo clasifica el frijol como en buen estado sin daños visibles.'],
      whatToDo: ['Mantén monitoreo regular. Rota cultivos en el siguiente ciclo para prevenir enfermedades.'],
    ),
    'Frijol_Danados': DiseaseInfo(
      cropName: 'Frijol',
      diseaseName: 'Grano dañado',
      scientificName: '',
      severity: 'Moderada',
      whatIs: ['El modelo detecta daños visibles en el frijol. Puede ser causado por hongos, insectos o daño mecánico durante cosecha.'],
      whatToDo: ['Separa los granos dañados de los sanos. Inspecciona el lote completo. Identifica la causa del daño con un especialista.'],
      ifNoAction: 'Los granos dañados pueden tener micotoxinas que los hacen no aptos para consumo. El daño puede extenderse al almacén.',
    ),

    // ── Uva ──────────────────────────────────────────────────────────────────
    'Grape___Black_rot': DiseaseInfo(
      cropName: 'Uva',
      diseaseName: 'Podredumbre negra',
      scientificName: 'Guignardia bidwellii',
      severity: 'Critica',
      whatIs: ['Hongo que produce manchas circulares marrones en hojas y pudre totalmente los frutos, que se momifican. Alta humedad y temperatura de 20–30 °C lo activan.'],
      whatToDo: ['Elimina frutos momificados y restos de cosecha. Aplica fungicida preventivo (miclobutanil 12.5% a 0.4 ml/L) cada 10–14 días en períodos húmedos.'],
      ifNoAction: 'Puede destruir el 80% de los frutos y el inóculo persiste momificado para el siguiente ciclo.',
    ),
    'Grape___Esca_(Black_Measles)': DiseaseInfo(
      cropName: 'Uva',
      diseaseName: 'Esca (sarampión negro)',
      scientificName: 'Phaeomoniella chlamydospora',
      severity: 'Critica',
      whatIs: ['Complejo de hongos que infecta la madera de la vid. Produce manchas "tigre" en hojas y bayas con manchas oscuras. Enfermedad de madera sin cura.'],
      whatToDo: ['Elimina y destruye ramas afectadas. Poda fuera de períodos húmedos. Protege cortes grandes con pasta fungicida. No tiene tratamiento curativo.'],
      ifNoAction: 'El árbol puede morir en unos años. La infección en madera es permanente.',
    ),
    'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)': DiseaseInfo(
      cropName: 'Uva',
      diseaseName: 'Tizón foliar (Isariopsis)',
      scientificName: 'Pseudocercospora vitis',
      severity: 'Moderada',
      whatIs: ['Hongo que produce manchas angulares en hojas con necrosis marginal. Aparece al final de la temporada en condiciones húmedas.'],
      whatToDo: ['Aplica fungicida cúprico (3 g/L) o mancozeb (2 g/L). Recoge y destruye hojas caídas infectadas.'],
      ifNoAction: 'Defoliación prematura que debilita la vid para el siguiente ciclo productivo.',
    ),
    'Grape___healthy': DiseaseInfo(
      cropName: 'Uva',
      diseaseName: 'Planta sana',
      scientificName: '',
      severity: 'Saludable',
      whatIs: ['El modelo no detecta signos de enfermedad activa en la imagen.'],
      whatToDo: ['Monitoreo semanal. Buena aireación del dosel reduce el riesgo de mildiu y oídio.'],
    ),

    // ── Durazno ──────────────────────────────────────────────────────────────
    'Peach___Bacterial_spot': DiseaseInfo(
      cropName: 'Durazno',
      diseaseName: 'Mancha bacteriana',
      scientificName: 'Xanthomonas arboricola pv. pruni',
      severity: 'Moderada',
      whatIs: ['Bacteria que produce manchas acuosas angulares en hojas y lesiones hundidas en frutos. Se propaga con lluvia y temperatura >25 °C.'],
      whatToDo: ['Aplica cobre bactericida (oxicloruro 3 g/L) preventivamente desde brotación. Mejora aireación con podas de formación.'],
      ifNoAction: 'Defoliación severa y pérdida de calidad de frutos que los hacen no comercializables.',
    ),
    'Peach___healthy': DiseaseInfo(
      cropName: 'Durazno',
      diseaseName: 'Planta sana',
      scientificName: '',
      severity: 'Saludable',
      whatIs: ['El modelo no detecta signos de enfermedad activa en la imagen.'],
      whatToDo: ['Mantén podas de formación y aclareo de frutos para buen desarrollo.'],
    ),

    // ── Pimienta ─────────────────────────────────────────────────────────────
    'Pepper,_bell___Bacterial_spot': DiseaseInfo(
      cropName: 'Pimienta',
      diseaseName: 'Mancha bacteriana',
      scientificName: 'Xanthomonas euvesicatoria',
      severity: 'Moderada',
      whatIs: ['Bacteria que produce manchas acuosas en hojas y frutos que se vuelven necróticas. Alta humedad y temperaturas de 24–30 °C la favorecen.'],
      whatToDo: ['Aplica cobre bactericida (3 g/L) preventivamente. Evita el riego por aspersión. Usa semilla certificada sin patógenos.'],
      ifNoAction: 'Pérdida de hasta el 50% de la cosecha con daños severos en frutos.',
    ),
    'Pepper,_bell___healthy': DiseaseInfo(
      cropName: 'Pimienta',
      diseaseName: 'Planta sana',
      scientificName: '',
      severity: 'Saludable',
      whatIs: ['El modelo no detecta signos de enfermedad activa en la imagen.'],
      whatToDo: ['Mantén buen drenaje y fertilización. Monitoreo semanal del tallo y raíces.'],
    ),

    // ── Papa ─────────────────────────────────────────────────────────────────
    'Potato___Early_blight': DiseaseInfo(
      cropName: 'Papa',
      diseaseName: 'Tizón temprano',
      scientificName: 'Alternaria solani',
      severity: 'Moderada',
      whatIs: ['Hongo que afecta hojas maduras con manchas en forma de diana con anillos concéntricos. Temperatura de 25–30 °C y humedad nocturna lo favorecen.'],
      whatToDo: ['Mejora la nutrición nitrogenada. Aplica mancozeb (80% a 2.5 g/L) cada 10 días como preventivo. Riega en la mañana.'],
      ifNoAction: 'Reducción del rendimiento del 20–30% y cosecha anticipada si la defoliación es severa.',
    ),
    'Potato___Late_blight': DiseaseInfo(
      cropName: 'Papa',
      diseaseName: 'Tizón tardío',
      scientificName: 'Phytophthora infestans',
      severity: 'Critica',
      whatIs: ['El patógeno más destructivo de la papa. Un ciclo infeccioso con lluvia y temperatura de 10–20 °C puede destruir un campo en 3–7 días.'],
      whatToDo: ['ACTÚA HOY. Aplica fungicida sistémico (cymoxanil+mancozeb 2 g/L). Elimina partes afectadas. Mejora aireación y reduce riego.'],
      ifNoAction: 'Pérdida total de la cosecha en 7–10 días. Daño en tubérculos imposibilita comercialización.',
    ),
    'Potato___healthy': DiseaseInfo(
      cropName: 'Papa',
      diseaseName: 'Planta sana',
      scientificName: '',
      severity: 'Saludable',
      whatIs: ['El modelo no detecta signos de enfermedad activa en la imagen.'],
      whatToDo: ['Monitoreo diario en períodos lluviosos. El tizón tardío puede aparecer en horas.'],
    ),

    // ── Frambuesa ────────────────────────────────────────────────────────────
    'Raspberry___healthy': DiseaseInfo(
      cropName: 'Frambuesa',
      diseaseName: 'Planta sana',
      scientificName: '',
      severity: 'Saludable',
      whatIs: ['El modelo no detecta signos de enfermedad activa en la imagen.'],
      whatToDo: ['Poda anual de los tallos viejos tras cosecha. Mantén densidad adecuada.'],
    ),

    // ── Soja ─────────────────────────────────────────────────────────────────
    'Soybean___healthy': DiseaseInfo(
      cropName: 'Soja',
      diseaseName: 'Planta sana',
      scientificName: '',
      severity: 'Saludable',
      whatIs: ['El modelo no detecta signos de enfermedad activa en la imagen.'],
      whatToDo: ['Monitoreo intensivo en períodos húmedos. La roya asiática puede aparecer en cualquier estado.'],
    ),

    // ── Calabaza (Squash) ─────────────────────────────────────────────────────
    'Squash___Powdery_mildew': DiseaseInfo(
      cropName: 'Calabaza',
      diseaseName: 'Mildiu polvoroso',
      scientificName: 'Erysiphe cichoracearum',
      severity: 'Moderada',
      whatIs: ['Hongo que produce polvo blanco sobre ambas caras de las hojas. Clima seco y cálido con noches frescas lo favorece.'],
      whatToDo: ['Aplica azufre mojable (2 g/L) cada 10 días. Evita exceso de nitrógeno que hace las plantas más susceptibles.'],
      ifNoAction: 'Pérdida de capacidad fotosintética y reducción del rendimiento del 20–40%.',
    ),

    // ── Fresa ────────────────────────────────────────────────────────────────
    'Strawberry___Leaf_scorch': DiseaseInfo(
      cropName: 'Fresa',
      diseaseName: 'Quemadura foliar',
      scientificName: 'Diplocarpon earlianum',
      severity: 'Moderada',
      whatIs: ['Hongo que produce manchas irregulares púrpura-rojizas en hojas que coalescen causando necrosis. Condiciones húmedas y temperaturas de 16–21 °C lo activan.'],
      whatToDo: ['Elimina hojas afectadas. Aplica captán (50% a 2 g/L) o azoxistrobina (0.5 ml/L) cada 10–14 días. Mejora la aireación.'],
      ifNoAction: 'Defoliación severa debilita las plantas y reduce la producción un 25–50%.',
    ),
    'Strawberry___healthy': DiseaseInfo(
      cropName: 'Fresa',
      diseaseName: 'Planta sana',
      scientificName: '',
      severity: 'Saludable',
      whatIs: ['El modelo no detecta signos de enfermedad activa en la imagen.'],
      whatToDo: ['Mantén riego por goteo y mulching para reducir humedad ambiental.'],
    ),

    // ── Tomate ───────────────────────────────────────────────────────────────
    'Tomato___Bacterial_spot': DiseaseInfo(
      cropName: 'Tomate',
      diseaseName: 'Mancha bacteriana',
      scientificName: 'Xanthomonas campestris pv. vesicatoria',
      severity: 'Moderada',
      whatIs: ['Bacteria que produce manchas acuosas pequeñas en hojas y frutos que se vuelven necrosis hundidas. Lluvia y temperatura de 24–30 °C la activan.'],
      whatToDo: ['Aplica cobre bactericida (oxicloruro 3 g/L) preventivamente. Evita el riego por aspersión. Usa semilla certificada.'],
      ifNoAction: 'Pérdida de hasta el 50% de frutos en temporadas húmedas.',
    ),
    'Tomato___Early_blight': DiseaseInfo(
      cropName: 'Tomate',
      diseaseName: 'Tizón temprano',
      scientificName: 'Alternaria solani',
      severity: 'Moderada',
      whatIs: ['Hongo que produce manchas con anillos concéntricos tipo "diana" comenzando en hojas bajas. Temperatura de 25–30 °C y humedad nocturna alta lo favorecen.'],
      whatToDo: ['Mejora la fertilización con fósforo y potasio. Aplica clorotalonil (75% a 2.5 g/L) cada 7–10 días. Riega en la mañana.'],
      ifNoAction: 'Defoliación severa expone los frutos y reduce el rendimiento final un 30–50%.',
    ),
    'Tomato___Late_blight': DiseaseInfo(
      cropName: 'Tomate',
      diseaseName: 'Tizón tardío',
      scientificName: 'Phytophthora infestans',
      severity: 'Critica',
      whatIs: ['El mismo patógeno que destruyó cosechas de papa históricamente. En tomate avanza igual de rápido en condiciones frías y húmedas. Emergencia agrícola.'],
      whatToDo: ['ACTÚA INMEDIATAMENTE. Aplica cymoxanil+mancozeb (2 g/L) hoy. Elimina partes afectadas. Mejora aireación. Reduce riego.'],
      ifNoAction: 'Sin tratamiento urgente destruye el campo completo en 5–7 días. Riesgo de propagación a parcelas vecinas.',
    ),
    'Tomato___Leaf_Mold': DiseaseInfo(
      cropName: 'Tomate',
      diseaseName: 'Moho foliar',
      scientificName: 'Passalora fulva',
      severity: 'Moderada',
      whatIs: ['Hongo que produce manchas amarillas pálidas en el haz y moho verde-oliváceo denso en el envés. Exclusivo de invernaderos y condiciones de alta humedad.'],
      whatToDo: ['Reduce humedad y mejora ventilación. Aplica azoxistrobina (25% a 0.5 ml/L) o difenoconazol (25% a 0.5 ml/L) cada 10 días.'],
      ifNoAction: 'Pérdida del 30–50% del potencial de rendimiento en condiciones de invernadero con alta humedad.',
    ),
    'Tomato___Septoria_leaf_spot': DiseaseInfo(
      cropName: 'Tomate',
      diseaseName: 'Mancha de Septoria',
      scientificName: 'Septoria lycopersici',
      severity: 'Moderada',
      whatIs: ['Hongo que produce manchas circulares pequeñas con centro gris y borde oscuro, comenzando en hojas bajas. Alta humedad y temperatura de 20–25 °C lo favorecen.'],
      whatToDo: ['Elimina hojas afectadas. Aplica clorotalonil (75% a 2.5 g/L) o mancozeb cada 7–10 días. Evita mojar hojas al regar.'],
      ifNoAction: 'Defoliación progresiva desde la base que puede dejar al tomate sin hojas funcionales.',
    ),
    'Tomato___Spider_mites Two-spotted_spider_mite': DiseaseInfo(
      cropName: 'Tomate',
      diseaseName: 'Araña roja bimaculada',
      scientificName: 'Tetranychus urticae',
      severity: 'Leve',
      whatIs: ['Ácaro (no hongo ni bacteria) que produce punteado amarillo en hojas y telaraña fina en el envés. Clima seco y caluroso lo favorece.'],
      whatToDo: ['Aplica acaricida (abamectina 1.8% a 0.5 ml/L) o azufre. Riega las plantas para aumentar humedad ambiental que frena su reproducción.'],
      ifNoAction: 'En infestaciones altas puede defoliar completamente el cultivo en verano.',
    ),
    'Tomato___Target_Spot': DiseaseInfo(
      cropName: 'Tomate',
      diseaseName: 'Mancha diana',
      scientificName: 'Corynespora cassiicola',
      severity: 'Moderada',
      whatIs: ['Hongo que produce manchas con anillos concéntricos en hojas, tallos y frutos. Clima cálido y húmedo lo favorece. Común en regiones tropicales.'],
      whatToDo: ['Aplica azoxistrobina (25% a 0.5 ml/L) o difenoconazol cada 10–14 días. Elimina hojas afectadas y mejora aireación.'],
      ifNoAction: 'Pérdida de calidad de frutos y defoliación que reduce rendimiento un 30–40%.',
    ),
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus': DiseaseInfo(
      cropName: 'Tomate',
      diseaseName: 'Virus del rizado amarillo',
      scientificName: 'Tomato yellow leaf curl virus',
      severity: 'Critica',
      whatIs: ['Virus transmitido por la mosca blanca (Bemisia tabaci). Produce hojas pequeñas, enrolladas hacia arriba y amarillas. No tiene cura. Muy destructivo.'],
      whatToDo: ['Controla la mosca blanca con insecticida sistémico (imidacloprid). Elimina plantas muy afectadas. Usa variedades resistentes en el siguiente ciclo.'],
      ifNoAction: 'Puede infectar toda la parcela rápidamente. Pérdida total de la producción en plantas infectadas.',
    ),
    'Tomato___Tomato_mosaic_virus': DiseaseInfo(
      cropName: 'Tomate',
      diseaseName: 'Virus del mosaico del tomate',
      scientificName: 'Tomato mosaic virus',
      severity: 'Leve',
      whatIs: ['Virus transmitido mecánicamente por manos y herramientas. Produce mosaico verde claro-oscuro en hojas. No tiene cura directa.'],
      whatToDo: ['Desinfecta herramientas con lejía diluida (10%). Lava manos antes de manipular plantas. Elimina plantas muy afectadas.'],
      ifNoAction: 'Reduce rendimiento un 20–40% y puede propagarse a toda la parcela.',
    ),
    'Tomato___healthy': DiseaseInfo(
      cropName: 'Tomate',
      diseaseName: 'Planta sana',
      scientificName: '',
      severity: 'Saludable',
      whatIs: ['El modelo no detecta signos de enfermedad activa en la imagen.'],
      whatToDo: ['Excelente estado. Monitorea cada semana y mantén buen manejo de riego.'],
    ),
  };
}
