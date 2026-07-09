// =============================================================================
// AgroGraph-MAS — Endpoints de API Centralizados
// =============================================================================
// Fuente: Pantallas del proyecto Stitch 9941199551312199248
// =============================================================================

/// Configuracion centralizada de todos los endpoints del backend.
abstract final class ApiEndpoints {
  ApiEndpoints._();

  // Base URL del microservicio de usuarios (incluye prefijo /api/v1).
  static const String baseUrl = 'http://174.129.218.190/api/v1';

  // Base URL del microservicio de cultivos (Nginx en puerto 80, sin puerto explícito).
  static const String cultivosBaseUrl = 'http://3.217.217.227/api/v1';

  // Base URL del microservicio LLM/RAG (diagnóstico enriquecido).
  static const String llmBaseUrl = 'http://52.1.110.21:8000';

  static const int defaultTimeoutMs = 30000;
  static const int connectTimeoutMs = 15000;
  // Timeout extendido para el LLM (Ollama puede tardar hasta 120 s).
  static const int llmTimeoutMs = 180000;

  // -- AUTH (Bienvenida / Registro de Cuenta) --
  static const AuthEndpoints auth = AuthEndpoints._();

  // -- SUBSCRIPTION (Seleccion de Plan / Precios Plan Pro) --
  static const SubscriptionEndpoints subscription = SubscriptionEndpoints._();

  // -- HOME (Inicio / Dashboard) --
  static const HomeEndpoints home = HomeEndpoints._();

  // -- DIAGNOSIS (Captura de Cultivo / Resultado del Diagnostico) --
  static const DiagnosisEndpoints diagnosis = DiagnosisEndpoints._();

  // -- TREATMENT (Agenda de Tratamiento) --
  static const TreatmentEndpoints treatment = TreatmentEndpoints._();

  // -- PARCELS (Mis Parcelas) --
  static const ParcelsEndpoints parcels = ParcelsEndpoints._();

  // -- CULTIVOS microservicio (catálogo + selecciones) --
  static const CultivosApiEndpoints cultivosCatalog = CultivosApiEndpoints._();
  static const SeleccionesApiEndpoints selecciones = SeleccionesApiEndpoints._();

  // -- ECONOMICS (Analisis Economico) --
  static const EconomicsEndpoints economics = EconomicsEndpoints._();

  // -- PROFILE (Perfil) --
  static const ProfileEndpoints profile = ProfileEndpoints._();

  // -- SYNC (Offline-First) --
  static const SyncEndpoints sync = SyncEndpoints._();

  // -- APRENDIZ (Aprendiz Agrícola) --
  static const AprendizEndpoints aprendiz = AprendizEndpoints._();

  // -- APRENDIZ / AGENDA (módulo independiente, endpoint aún no expuesto) --
  static const AgendaEndpoints agenda = AgendaEndpoints._();

  // -- LLM / RAG (Diagnóstico enriquecido) --
  static const LlmEndpoints llm = LlmEndpoints._();

  // -- PRODUCTOS (Recomendaciones post-diagnóstico) --
  // Host: 44.196.107.153:80 — servicio independiente con X-API-Key
  static const String productsBaseUrl = 'http://44.196.107.153';
  static const int productsTimeoutMs = 15000;
  // La API key la proporciona el equipo backend.
  // Para no hardcodearla, pásala en build-time:
  //   flutter run --dart-define=PRODUCTS_API_KEY=tu_clave
  static const String productsApiKey = String.fromEnvironment(
    'PRODUCTS_API_KEY',
    defaultValue: '4b7e2a9f1c6d3e8b5a0f4c9e2d7b1a6f3c8e5b2d9f0a4c7e1b6d3f8a5c2e9b4d',
  );

  static const ProductsEndpoints products = ProductsEndpoints._();
}

class AuthEndpoints {
  const AuthEndpoints._();

  // Endpoints publicos (no requieren Authorization header)
  String get login => '/auth/login';
  String get registerAgricultor => '/auth/register/agricultor';
  String get registerAprendiz => '/auth/register/aprendiz';
  String get refreshToken => '/auth/refresh';
  String get logout => '/auth/logout';

  // Endpoint protegido: requiere rol admin
  String get registerAdmin => '/auth/register/admin';

  // Lista de paths publicos usada por el AuthInterceptor para omitir el header.
  List<String> get publicPaths => [
        login,
        registerAgricultor,
        registerAprendiz,
        refreshToken,
        logout,
      ];
}

class SubscriptionEndpoints {
  const SubscriptionEndpoints._();
  String get plans => '/subscriptions/plans';
  String get current => '/subscriptions/current';
  String get subscribe => '/subscriptions/subscribe';
  String get cancel => '/subscriptions/cancel';
}

class HomeEndpoints {
  const HomeEndpoints._();
  String get dashboard => '/dashboard';
  String get summary => '/dashboard/summary';
  String get alerts => '/dashboard/alerts';
  String get weather => '/dashboard/weather';
}

class DiagnosisEndpoints {
  const DiagnosisEndpoints._();
  String get analyze => '/diagnosis/analyze';
  String get history => '/diagnosis/history';
  String byId(String id) => '/diagnosis/$id';
  String get diseases => '/diagnosis/diseases';
}

class TreatmentEndpoints {
  const TreatmentEndpoints._();
  String get agenda => '/treatments/agenda';
  String get create => '/treatments';
  String byId(String id) => '/treatments/$id';
  String markComplete(String id) => '/treatments/$id/complete';
}

class ParcelsEndpoints {
  const ParcelsEndpoints._();
  String get list => '/parcels';
  String get create => '/parcels';
  String byId(String id) => '/parcels/$id';
  String crops(String id) => '/parcels/$id/crops';
  String health(String id) => '/parcels/$id/health';
}

class EconomicsEndpoints {
  const EconomicsEndpoints._();
  String get overview => '/economics/overview';
  String get costs => '/economics/costs';
  String get revenue => '/economics/revenue';
  String byParcel(String id) => '/economics/parcels/$id';
}

class ProfileEndpoints {
  const ProfileEndpoints._();
  String get me => '/users/me';
  String get update => '/users/me';
  String get avatar => '/users/me/avatar';
  String get settings => '/users/me/settings';

  // TODO: endpoint aun no expuesto por el backend — progreso/gamificacion
  // del perfil Aprendiz (nivel, XP, racha). Mientras tanto se calcula
  // localmente (ver AprendizProfileRepositoryImpl).
  String get progress => '/users/me/progress';
}

class SyncEndpoints {
  const SyncEndpoints._();
  String get status => '/sync/status';
  String get push => '/sync/push';
  String get pull => '/sync/pull';
  String get conflicts => '/sync/conflicts';
}

class AprendizEndpoints {
  const AprendizEndpoints._();

  // TODO: Agregar y documentar en el README de usuarios/API del backend
  String get cropPlan => '/aprendiz/crop-plan';
  String get cropHealth => '/aprendiz/crop-health';
  String activityStatus(String activityId) => '/aprendiz/crop-plan/activities/$activityId';

  // TODO: Documentar en backend el endpoint de historial (Pieza 2)
  String get history => '/aprendiz/history';
}

/// Endpoints del modulo Agenda (independiente de crop-plan).
/// TODO: reemplazar por la URL real cuando el backend exponga el modulo.
class AgendaEndpoints {
  const AgendaEndpoints._();

  String get overview => '/aprendiz/agenda';
  String completeActivity(String activityId) => '/aprendiz/agenda/activities/$activityId/complete';
  String postponeActivity(String activityId) => '/aprendiz/agenda/activities/$activityId/postpone';
}

// =============================================================================
// CULTIVOS MICROSERVICIO (http://3.217.217.227:8001/api/v1)
// Usa el mismo JWT emitido por el microservicio de Usuarios.
// =============================================================================

class CultivosApiEndpoints {
  const CultivosApiEndpoints._();

  // Catálogo (accesible por todos los roles autenticados).
  String get catalog => '/cultivos';
  String byId(String id) => '/cultivos/$id';
}

class SeleccionesApiEndpoints {
  const SeleccionesApiEndpoints._();

  // Selección de cultivo: agricultor / aprendiz registran su parcela.
  String get create => '/selecciones';
  String get myList => '/selecciones/mis-selecciones';
  String get myListAlias => '/selecciones/me';
  String byId(String id) => '/selecciones/$id';
  String currentByUser(String userId) => '/selecciones/usuario/$userId/actual';
}

// =============================================================================
// LLM / RAG MICROSERVICIO (http://52.1.110.21:8000)
// Acepta el mismo JWT del microservicio de Usuarios.
// =============================================================================

class LlmEndpoints {
  const LlmEndpoints._();

  /// Endpoint principal: CNN result + texto de usuario → diagnóstico enriquecido.
  String get consultar => '/api/v1/consultar';
}

// =============================================================================
// PRODUCTOS MICROSERVICIO (http://44.196.107.153)
// Auth: POST /auth/token (X-API-Key) → JWT → Bearer en cada request.
// =============================================================================

class ProductsEndpoints {
  const ProductsEndpoints._();

  /// POST /auth/token?user_type=agricultor_experimentado — devuelve JWT.
  String get authToken => '/auth/token';

  /// GET /products?disease=&crop=&per_page= — lista de productos.
  String get products => '/products';
}

