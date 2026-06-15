# Gestion de Informacion Sensible en AgroGraph-MAS

En estricto cumplimiento con los lineamientos de "Informacion Sensible: Un Enfoque Integral", a continuacion se expone la identificacion, analisis de impacto, clasificacion y medidas de proteccion aplicables a los datos manejados en el desarrollo de **AgroGraph-MAS**.

---

## 1. Identificacion de la Informacion Sensible

Durante la construccion del Frontend y los diferentes flujos (Registro, Suscripcion, Diagnostico, Economia, etc.), se han identificado los siguientes activos criticos:

### A. Datos Personales
- **Identificadores Directos**: Nombre completo del agricultor, correo electronico y numero de telefono (recolectados en el registro y en el formulario de facturacion de `checkout_page.dart`).
- **Identificaciones Oficiales**: Identificacion Fiscal (RFC/ID) requerida en el proceso de pago para emision de comprobantes.

### B. Datos Financieros
- **Informacion de Pago Seguro**: Numeros de tarjeta (16 digitos), fecha de vencimiento (MM/AA) y codigo de seguridad (CVV) recolectados durante la Etapa 2 de la pasarela de pagos.
- **Saldos e Historial**: Registros de ingresos y egresos, balances financieros generales procesados en el modulo de Economia (`economics_page.dart`).

### C. Datos Estrategicos o Comerciales
- **Propiedad y Operativa Agricola**: Nomenclatura de parcelas (ej. "Milpa Norte", "Huerta Baja"), ubicacion (GPS/coordenadas inferidas), y rutinas de cultivo administradas en la agenda agronomica (`treatment_page.dart`).
- **Secretos de Produccion / Alertas**: Las fotografias de cultivos capturadas por la camara (`diagnosis_page.dart`) y los resultados predictivos de la IA sobre brotes (ej. Gusano cogollero, Tizon tardio) representan inteligencia de negocio altamente delicada.

### D. Credenciales de Acceso
- **Autenticacion**: Contrasenas de usuario ingresadas y validadas a traves del `AuthBloc`.
- **Sesiones Nativas**: Tokens JWT o hashes de sesion guardados persistentemente de forma local mediante Hive (`auth_local_datasource.dart`).

---

## 2. Analisis de Impacto

Aplicando la triada CIA (Confidencialidad, Integridad y Disponibilidad) al caso de AgroGraph:

- **Confidencialidad**: Si se divulga el estado de salud de las parcelas de un agricultor (ej. una fuerte plaga detectada por nuestra IA), la competencia o los intermediarios del mercado podrian utilizarlo en su contra afectando los precios. Peor aun, una brecha en los datos de la tarjeta de credito impactaria directamente su patrimonio y la reputacion de la app.
- **Integridad**: Si un atacante altera los registros de la agenda agronomica o el historial de evaluacion, el agricultor podria omitir una "segunda aplicacion" de pesticida o realizarla de forma innecesaria. Esto podria provocar toxicidad en el cultivo o perdida total de la cosecha.
- **Disponibilidad**: Si la aplicacion pierde disponibilidad (los datos no cargan), el usuario no podria recibir las "Alertas Regionales" de propagacion a tiempo, exponiendo su terreno a riesgo inminente. Nuestro diseno *Offline-First* con Hive previene de manera directa que este impacto ocurra por falta de senal en campo.

---

## 3. Clasificacion de la Informacion

Para definir los controles de acceso correctos, la informacion en AgroGraph se estratifica de la siguiente manera:

1. **Secreta / Ultra-confidencial**:
   - Contrasenas en texto plano/hash, codigo CVV de tarjetas, claves criptograficas y llaves privadas empleadas por la aplicacion para firmar peticiones de la pasarela.
2. **Confidencial**:
   - Numeros de tarjeta de debito/credito, identificaciones (RFC), diagnosticos detallados por parcela, reportes economicos, y ubicaciones precisas de cultivo.
3. **Interna**:
   - Flujos de navegacion del usuario, configuraciones del `ProfilePage`, esquemas de interfaz y arquitectura de datos.
4. **Publica**:
   - El catalogo de precios de los planes (Free, Premium, Anual), alertas sanitarias generales desvinculadas de duenos especificos, y librerias Open Source integradas.

---

## 4. Proteccion de la Informacion Sensible

Para mitigar los riesgos derivados del analisis de impacto, la ingenieria de AgroGraph-MAS asume los siguientes compromisos tecnicos:

- **Cifrado Fuerte**: La base de datos local (Hive) donde se hospeda la sesion y datos temporales debe utilizar `HiveAesCipher` asegurando el almacenamiento (reposo). Las transacciones de `CheckoutPage` hacia las APIs transitaran cifradas obligatoriamente (TLS 1.2+).
- **Controles de Acceso Estrictos**: Se maneja un flujo de `AuthGate` para verificar credenciales antes de mostrar datos confidenciales, y se gestionan las memorias de forma segura (uso de `obscureText` en campos de contrasenas/CVV, y llamadas a `dispose()` para limpiar memoria en formularios).
- **Respaldos y Recuperacion (Resiliencia)**: Los repositorios locales y el control de red (*NetworkFailure*) permiten guardar las fotos en "cola" de forma local hasta que el dispositivo retome conectividad, asegurando una recuperacion limpia.

---

## 5. Importancia de la Gestion Sensible en AgroGraph

El manejo pulcro y profesional de esta informacion es vital porque:
1. **Proteccion de la Privacidad**: Asegura que el trabajo privado, el nivel economico y las vulnerabilidades sanitarias de un productor no lleguen a manos de terceros.
2. **Cumplimiento Legal**: Posiciona a AgroGraph en acatamiento de regulaciones vigentes en materia de proteccion de datos financieros y personales.
3. **Confianza Total del Cliente**: Al implementar este rigor en el codigo (vistas limpias, recoleccion justa, advertencias seguras de "procesamiento"), el agricultor confiara en escalar a la suscripcion **Pro**, garantizando el exito comercial del proyecto.
