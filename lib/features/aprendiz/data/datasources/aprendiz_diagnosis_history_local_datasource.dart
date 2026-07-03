import 'package:path/path.dart' as path_pkg;
import 'package:sqflite/sqflite.dart';

import '../../../diagnosis/domain/entities/diagnosis_entity.dart';
import '../../../diagnosis/domain/entities/llm_response_entity.dart';
import '../models/aprendiz_diagnosis_model.dart';

/// Historial de diagnósticos del Aprendiz persistido en SQLite (almacenamiento
/// local del dispositivo), aislado por completo de la caja/tabla que usa el
/// perfil Agricultor — cada perfil tiene su propio almacén.
abstract interface class AprendizDiagnosisHistoryLocalDataSource {
  Future<void> insertDiagnosis(DiagnosisEntity entity, {required String? userId});

  Future<List<AprendizDiagnosisModel>> getDiagnoses({required String userId});

  Future<void> updateLlmResponse({
    required String diagnosisId,
    required LlmResponseEntity llmResponse,
  });
}

class AprendizDiagnosisHistoryLocalDataSourceImpl implements AprendizDiagnosisHistoryLocalDataSource {
  Database? _db;
  Future<Database>? _dbFuture;

  Future<Database> get _database {
    if (_db != null) return Future.value(_db!);
    return _dbFuture ??= _initDatabase().then((db) {
      _db = db;
      _dbFuture = null;
      return db;
    });
  }

  Future<Database> _initDatabase() async {
    final dbsPath = await getDatabasesPath();
    final dbPath = path_pkg.join(dbsPath, 'aprendiz_diagnosis.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS aprendiz_diagnoses (
            id                TEXT PRIMARY KEY,
            user_id           TEXT,
            disease_name      TEXT NOT NULL,
            crop_name         TEXT NOT NULL,
            confidence        REAL NOT NULL,
            image_path        TEXT,
            diagnosed_at      TEXT NOT NULL,
            is_pending_sync   INTEGER NOT NULL DEFAULT 0,
            status_label      TEXT NOT NULL,
            parcel_id         TEXT,
            parcel_name       TEXT,
            llm_response_json TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_aprendiz_diagnoses_user ON aprendiz_diagnoses(user_id)',
        );
      },
    );
  }

  @override
  Future<void> insertDiagnosis(DiagnosisEntity entity, {required String? userId}) async {
    final db = await _database;
    final model = AprendizDiagnosisModel.fromEntity(entity, userId: userId);
    await db.insert(
      'aprendiz_diagnoses',
      model.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<AprendizDiagnosisModel>> getDiagnoses({required String userId}) async {
    final db = await _database;
    final rows = await db.query(
      'aprendiz_diagnoses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'diagnosed_at DESC',
    );
    return rows.map(AprendizDiagnosisModel.fromRow).toList();
  }

  @override
  Future<void> updateLlmResponse({
    required String diagnosisId,
    required LlmResponseEntity llmResponse,
  }) async {
    final db = await _database;
    await db.update(
      'aprendiz_diagnoses',
      {'llm_response_json': AprendizDiagnosisModel.encodeLlmResponse(llmResponse)},
      where: 'id = ?',
      whereArgs: [diagnosisId],
    );
  }
}
