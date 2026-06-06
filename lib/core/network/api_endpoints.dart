// =============================================================================
// AgroGraph-MAS — Endpoints de API Centralizados
// =============================================================================
// Fuente: Pantallas del proyecto Stitch 9941199551312199248
// =============================================================================

/// Configuracion centralizada de todos los endpoints del backend.
abstract final class ApiEndpoints {
  ApiEndpoints._();

  // -- CONFIGURACION BASE --
  static const String baseUrl = 'https://api.agrograph-mas.com/v1';
  static const int defaultTimeoutMs = 30000;
  static const int connectTimeoutMs = 15000;

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

  // -- ECONOMICS (Analisis Economico) --
  static const EconomicsEndpoints economics = EconomicsEndpoints._();

  // -- PROFILE (Perfil) --
  static const ProfileEndpoints profile = ProfileEndpoints._();

  // -- SYNC (Offline-First) --
  static const SyncEndpoints sync = SyncEndpoints._();
}

class AuthEndpoints {
  const AuthEndpoints._();
  String get login => '/auth/login';
  String get register => '/auth/register';
  String get refreshToken => '/auth/refresh';
  String get logout => '/auth/logout';
  String get forgotPassword => '/auth/forgot-password';
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
}

class SyncEndpoints {
  const SyncEndpoints._();
  String get status => '/sync/status';
  String get push => '/sync/push';
  String get pull => '/sync/pull';
  String get conflicts => '/sync/conflicts';
}

