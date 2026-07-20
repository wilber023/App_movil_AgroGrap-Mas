import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrograp_movil/core/error/failures.dart';
import 'package:agrograp_movil/features/agricultor/diagnosis/domain/entities/diagnosis_entity.dart';
import 'package:agrograp_movil/features/agricultor/diagnosis/domain/entities/llm_response_entity.dart';
import 'package:agrograp_movil/features/agricultor/diagnosis/domain/repositories/llm_diagnosis_repository.dart';
import 'package:agrograp_movil/features/agricultor/diagnosis/domain/usecases/get_llm_diagnosis_usecase.dart';
import 'package:agrograp_movil/features/agricultor/diagnosis/presentation/bloc/llm_diagnosis_cubit.dart';
import 'package:agrograp_movil/features/agricultor/parcels/domain/entities/cultivo_entity.dart';
import 'package:agrograp_movil/features/agricultor/parcels/domain/entities/parcel_entity.dart';
import 'package:agrograp_movil/features/agricultor/parcels/domain/repositories/parcel_repository.dart';
import 'package:agrograp_movil/features/agricultor/parcels/domain/usecases/get_parcel_region_local_usecase.dart';
import 'package:agrograp_movil/features/clustering/domain/entities/alerta_epidemiologica_entity.dart';
import 'package:agrograp_movil/features/clustering/domain/entities/estado_resumen_entity.dart';
import 'package:agrograp_movil/features/clustering/domain/repositories/clustering_repository.dart';
import 'package:agrograp_movil/features/clustering/domain/usecases/enviar_reporte_diagnostico_usecase.dart';

class _FakeLlmDiagnosisRepository implements LlmDiagnosisRepository {
  Either<Failure, LlmResponseEntity>? result;

  @override
  Future<Either<Failure, LlmResponseEntity>> consultar({
    required DiagnosisEntity diagnosis,
    required String rol,
    String? userText,
  }) async {
    return result!;
  }
}

ParcelEntity _parcel({
  required String seleccionId,
  required String cropName,
  required String region,
}) {
  return ParcelEntity(
    id: seleccionId,
    seleccionId: seleccionId,
    cultivoId: 'cultivo-$seleccionId',
    name: 'Parcela $seleccionId',
    cropName: cropName,
    areaSize: 1.0,
    region: region,
    status: 'Sin diagnostico',
    stageName: 'Siembra',
    stageProgress: 0,
    stageIndex: 0,
  );
}

/// Fake de [ParcelRepository]: solo implementa `getRegionLocal`/`getParcelsLocal`
/// (lo único que usa el reporte de diagnóstico), sobre una lista de parcelas
/// "cacheadas" en memoria. El resto lanza si se llegara a invocar, ya que la
/// integración prohíbe explícitamente consultar el microservicio de
/// Cultivos al momento del diagnóstico.
class _FakeParcelRepository implements ParcelRepository {
  final List<ParcelEntity> parcelasCacheadas;
  const _FakeParcelRepository(this.parcelasCacheadas);

  @override
  Future<String?> getRegionLocal(String seleccionId) async {
    for (final p in parcelasCacheadas) {
      if (p.seleccionId == seleccionId) return p.region;
    }
    return null;
  }

  @override
  Future<List<ParcelEntity>> getParcelsLocal() async => parcelasCacheadas;

  @override
  Future<Either<Failure, ParcelEntity>> addParcel(AddParcelParams params) =>
      throw UnimplementedError('no debe llamarse durante el reporte de diagnóstico');

  @override
  Future<Either<Failure, void>> deleteParcel(String seleccionId) =>
      throw UnimplementedError('no debe llamarse durante el reporte de diagnóstico');

  @override
  Future<Either<Failure, List<CultivoEntity>>> getCultivoCatalog() =>
      throw UnimplementedError('no debe llamarse durante el reporte de diagnóstico');

  @override
  Future<Either<Failure, ParcelEntity>> getParcelDetail(String seleccionId) =>
      throw UnimplementedError('no debe llamarse durante el reporte de diagnóstico');

  @override
  Future<Either<Failure, List<ParcelEntity>>> getParcels() =>
      throw UnimplementedError('no debe consultarse la red al momento del diagnóstico');
}

class _FakeClusteringRepository implements ClusteringRepository {
  final List<Map<String, String>> reportesEnviados = [];

  @override
  Future<void> enviarReporte({
    required String cultivo,
    required String plaga,
    required String estado,
  }) async {
    reportesEnviados.add({'cultivo': cultivo, 'plaga': plaga, 'estado': estado});
  }

  @override
  Future<Either<Failure, AlertaEpidemiologicaEntity>> getAlerta({String? estado}) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, MapaCampaniasEntity>> getMapaCampanias() => throw UnimplementedError();
}

DiagnosisEntity _diagnosis({
  String cropName = 'Maíz',
  String diseaseName = 'Tizón norteño foliar',
  String? parcelId,
}) {
  return DiagnosisEntity(
    id: 'diag1',
    diseaseName: diseaseName,
    cropName: cropName,
    confidence: 0.9,
    diagnosedAt: DateTime(2026, 7, 19),
    statusLabel: 'Detectado',
    parcelId: parcelId,
  );
}

const _llmResponseOk = LlmResponseEntity(
  diagnostico: 'Diagnóstico de prueba',
  tratamiento: 'Tratamiento de prueba',
  prevencion: 'Prevención de prueba',
  aprendizaje: '',
  fuentes: [],
  confianzaAjustada: 0.9,
  estado: 'reforzado',
  explicacion: '',
  sintomas: [],
  avisos: [],
  sinDocumentos: false,
);

void main() {
  late _FakeLlmDiagnosisRepository llmRepo;
  late _FakeClusteringRepository clusteringRepo;

  LlmDiagnosisCubit buildCubit(List<ParcelEntity> parcelasCacheadas) {
    llmRepo = _FakeLlmDiagnosisRepository()..result = const Right(_llmResponseOk);
    clusteringRepo = _FakeClusteringRepository();
    return LlmDiagnosisCubit(
      GetLlmDiagnosisUseCase(llmRepo),
      enviarReporteUseCase: EnviarReporteDiagnosticoUseCase(clusteringRepo),
      getParcelRegionLocalUseCase:
          GetParcelRegionLocalUseCase(_FakeParcelRepository(parcelasCacheadas)),
    );
  }

  Future<void> flushMicrotasks() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('parcelId exacto cacheado -> reporta cultivo/plaga/estado tal cual', () async {
    final cubit = buildCubit([
      _parcel(seleccionId: 'parcel1', cropName: 'Maíz', region: 'Suchiapa, Chiapas'),
    ]);

    await cubit.consultar(diagnosis: _diagnosis(parcelId: 'parcel1'), rol: 'agricultor');
    await flushMicrotasks();

    expect(clusteringRepo.reportesEnviados, [
      {'cultivo': 'Maíz', 'plaga': 'Tizón norteño foliar', 'estado': 'Suchiapa, Chiapas'},
    ]);
  });

  test(
    'diagnóstico genérico sin parcelId, con una sola parcela cacheada -> usa esa región '
    '(caso real: "Diagnosticar" desde inicio, no desde la ficha de una parcela)',
    () async {
      final cubit = buildCubit([
        _parcel(seleccionId: 'parcel1', cropName: 'Maíz', region: 'Suchiapa, Chiapas'),
      ]);

      await cubit.consultar(diagnosis: _diagnosis(parcelId: null), rol: 'agricultor');
      await flushMicrotasks();

      expect(clusteringRepo.reportesEnviados, [
        {'cultivo': 'Maíz', 'plaga': 'Tizón norteño foliar', 'estado': 'Suchiapa, Chiapas'},
      ]);
    },
  );

  test(
    'diagnóstico genérico sin parcelId, con varias parcelas -> usa la que coincide por cultivo',
    () async {
      final cubit = buildCubit([
        _parcel(seleccionId: 'parcel1', cropName: 'Café', region: 'Tuxtla Gutiérrez, Chiapas'),
        _parcel(seleccionId: 'parcel2', cropName: 'Maíz', region: 'Suchiapa, Chiapas'),
      ]);

      await cubit.consultar(diagnosis: _diagnosis(cropName: 'Maíz', parcelId: null), rol: 'agricultor');
      await flushMicrotasks();

      expect(clusteringRepo.reportesEnviados, [
        {'cultivo': 'Maíz', 'plaga': 'Tizón norteño foliar', 'estado': 'Suchiapa, Chiapas'},
      ]);
    },
  );

  test(
    'sin parcelId, varias parcelas y ninguna coincide por cultivo -> usa la primera con región '
    '(mejor una región aproximada que ningún reporte -- caso real: el usuario diagnostica un '
    'cultivo para el que no tiene parcela registrada)',
    () async {
      final cubit = buildCubit([
        _parcel(seleccionId: 'parcel1', cropName: 'Café', region: 'Tuxtla Gutiérrez, Chiapas'),
        _parcel(seleccionId: 'parcel2', cropName: 'Frijol', region: 'Comitán, Chiapas'),
      ]);

      await cubit.consultar(diagnosis: _diagnosis(cropName: 'Maíz', parcelId: null), rol: 'agricultor');
      await flushMicrotasks();

      expect(clusteringRepo.reportesEnviados, [
        {'cultivo': 'Maíz', 'plaga': 'Tizón norteño foliar', 'estado': 'Tuxtla Gutiérrez, Chiapas'},
      ]);
    },
  );

  test(
    'sin parcelId, varias parcelas y ninguna tiene región guardada -> no se envía (nada que usar)',
    () async {
      final cubit = buildCubit([
        _parcel(seleccionId: 'parcel1', cropName: 'Café', region: ''),
        _parcel(seleccionId: 'parcel2', cropName: 'Frijol', region: ''),
      ]);

      await cubit.consultar(diagnosis: _diagnosis(cropName: 'Maíz', parcelId: null), rol: 'agricultor');
      await flushMicrotasks();

      expect(clusteringRepo.reportesEnviados, isEmpty);
    },
  );

  test('sin parcelId y sin ninguna parcela cacheada (flujo Aprendiz) -> el reporte NO se envía', () async {
    final cubit = buildCubit([]);

    await cubit.consultar(diagnosis: _diagnosis(parcelId: null), rol: 'aprendiz');
    await flushMicrotasks();

    expect(clusteringRepo.reportesEnviados, isEmpty);
  });

  test('parcelId presente pero sin nada cacheado localmente -> no se envía (no inventa estado)', () async {
    final cubit = buildCubit([]);

    await cubit.consultar(diagnosis: _diagnosis(parcelId: 'parcel-sin-cache'), rol: 'agricultor');
    await flushMicrotasks();

    expect(clusteringRepo.reportesEnviados, isEmpty);
  });

  test('cultivo vacío -> no se envía aunque haya región y plaga', () async {
    final cubit = buildCubit([
      _parcel(seleccionId: 'parcel1', cropName: 'Maíz', region: 'Suchiapa, Chiapas'),
    ]);

    await cubit.consultar(
      diagnosis: _diagnosis(cropName: '   ', parcelId: 'parcel1'),
      rol: 'agricultor',
    );
    await flushMicrotasks();

    expect(clusteringRepo.reportesEnviados, isEmpty);
  });

  test('el diagnóstico se muestra igual aunque el reporte no se envíe', () async {
    final cubit = buildCubit([]);

    await cubit.consultar(diagnosis: _diagnosis(parcelId: null), rol: 'aprendiz');
    await flushMicrotasks();

    expect(cubit.state, isA<LlmDiagnosisLoaded>());
  });
}
