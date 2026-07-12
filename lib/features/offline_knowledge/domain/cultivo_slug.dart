// =============================================================================
// AgroGraph-MAS — cultivoSlug (offline_knowledge)
// Único lugar con esta lógica: reutilizado por el punto de integración de
// diagnóstico (diagnosis_result_page.dart) y por la gestión de descargas de
// Perfil (OfflinePackageManagerCubit) — no duplicar en otros archivos.
// =============================================================================

/// Normaliza un nombre de cultivo/enfermedad en español (ej. "Maíz") para
/// que coincida con los valores reales del backend (`crop_name`/
/// `disease_name` en GET /api/v1/offline/catalog, ver README_ofline.md).
///
/// Antes (Sprint 2) esta función quitaba acentos (slug ASCII, "Maíz" ->
/// "maiz"), asumiendo un contrato que nunca existió. El Sprint 3 confirmó
/// que el backend espera exactamente la misma normalización que ya usa el
/// flujo ONLINE contra este mismo servidor
/// (`LlmDiagnosisDataSourceImpl.consultar`: `diagnosis.cropName.toLowerCase()`
/// / `diagnosis.diseaseName.toLowerCase()`, sin quitar acentos) — así que
/// ahora hace exactamente lo mismo, para ser consistente con un flujo que
/// ya está validado contra el backend real.
String cultivoSlug(String value) => value.toLowerCase();
