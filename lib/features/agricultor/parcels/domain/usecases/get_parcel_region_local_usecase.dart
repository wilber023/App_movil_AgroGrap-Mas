import 'package:flutter/foundation.dart';

import '../entities/parcel_entity.dart';
import '../repositories/parcel_repository.dart';

/// Lee la Región/Comunidad de una parcela desde la caché local (sin llamar
/// al microservicio de Cultivos). Pensado para usos fire-and-forget donde
/// una consulta de red adicional no es aceptable (p. ej. reporte de
/// diagnóstico a Clustering).
///
/// Muchos diagnósticos no se inician desde la ficha de una parcela concreta
/// (p. ej. "Diagnosticar" genérico desde inicio), así que `parcelId` suele
/// venir `null`. En ese caso se resuelve, en orden:
/// 1) por el cultivo cacheado que coincide con el del diagnóstico;
/// 2) si no hay coincidencia (p. ej. el usuario diagnostica un cultivo para
///    el que no tiene una parcela registrada), por la primera parcela
///    cacheada que sí tenga una región guardada -- es la única señal de
///    ubicación que existe en la app hoy, y una región aproximada alimenta
///    mejor el sistema de Clustering que ningún reporte.
/// Todo sin red, únicamente sobre lo ya cacheado por
/// `getMisSelecciones()`/`crearSeleccion()`.
class GetParcelRegionLocalUseCase {
  final ParcelRepository repository;

  const GetParcelRegionLocalUseCase(this.repository);

  Future<String?> call({String? parcelId, String? cropName}) async {
    if (parcelId != null && parcelId.isNotEmpty) {
      final region = await repository.getRegionLocal(parcelId);
      if (region != null && region.trim().isNotEmpty) {
        _log('match exacto por parcelId=$parcelId -> region="$region"');
        return region;
      }
    }

    final parcels = await repository.getParcelsLocal();
    if (parcels.isEmpty) {
      _log('sin parcelas cacheadas localmente (parcelId=$parcelId, cropName=$cropName)');
      return null;
    }

    if (cropName != null && cropName.trim().isNotEmpty) {
      final match = _findByCropName(parcels, cropName);
      if (match != null && match.region.trim().isNotEmpty) {
        _log('match por cultivo="$cropName" -> seleccion=${match.seleccionId} region="${match.region}"');
        return match.region;
      }
    }

    for (final parcel in parcels) {
      if (parcel.region.trim().isNotEmpty) {
        _log(
          'sin match exacto por parcela/cultivo -- usando la primera parcela cacheada con región: '
          'seleccion=${parcel.seleccionId} cultivo="${parcel.cropName}" region="${parcel.region}"',
        );
        return parcel.region;
      }
    }

    _log(
      'sin match y ninguna parcela cacheada tiene región (parcelId=$parcelId, cropName=$cropName) -- '
      '${parcels.length} parcela(s): '
      '${parcels.map((p) => '${p.seleccionId}:"${p.cropName}"->region="${p.region}"').join(', ')}',
    );
    return null;
  }

  ParcelEntity? _findByCropName(List<ParcelEntity> parcels, String cropName) {
    final normalized = cropName.trim().toLowerCase();
    for (final parcel in parcels) {
      if (parcel.cropName.trim().toLowerCase() == normalized) return parcel;
    }
    return null;
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[GetParcelRegionLocal] $message');
  }
}
