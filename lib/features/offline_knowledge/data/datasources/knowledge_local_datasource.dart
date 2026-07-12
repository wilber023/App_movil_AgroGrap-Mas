// =============================================================================
// AgroGraph-MAS — KnowledgeLocalDataSource (offline_knowledge)
// SQLite dedicada a este feature: agro_knowledge.db (independiente de
// agro_offline.db, usada por la feature legacy features/agricultor/offline/).
// Ver agrograph_diagnostico_offline_embeddings.md, secciones 4, 8 y 9.
// =============================================================================

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/scored_entry.dart';
import '../../domain/entities/treatment_entry.dart';

/// Similitud coseno entre dos vectores de igual dimensión.
///
/// Pública y sin dependencias de SQLite para poder testearla de forma
/// aislada con vectores de prueba.
@visibleForTesting
double cosineSimilarity(List<double> a, List<double> b) {
  assert(a.length == b.length);
  double dot = 0, normA = 0, normB = 0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA == 0 || normB == 0) return 0;
  return dot / (math.sqrt(normA) * math.sqrt(normB));
}

abstract interface class KnowledgeLocalDataSource {
  /// Consulta exacta por `cultivo + id`.
  Future<TreatmentEntry?> querySQL(String cultivo, String id);

  /// Búsqueda por similitud coseno contra los embeddings guardados de un
  /// cultivo, devuelve las [topK] fichas con mayor score (descendente).
  Future<List<ScoredEntry>> vectorSearch({
    required String cultivo,
    required List<double> queryVector,
    required int topK,
  });

  /// Indexa un paquete completo ya parseado a JSON (ver contrato en la
  /// sección 8 del documento). Reemplaza el índice previo de ese cultivo.
  Future<void> insertPackage(Map<String, dynamic> json);

  /// Verifica si existe un paquete descargado para [cultivo].
  Future<bool> hasPackage(String cultivo);
}

class KnowledgeLocalDataSourceImpl implements KnowledgeLocalDataSource {
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
    final dbPath = path_pkg.join(dbsPath, 'agro_knowledge.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE knowledge_fichas (
            cultivo        TEXT NOT NULL,
            id             TEXT NOT NULL,
            enfermedad     TEXT NOT NULL,
            sintomas       TEXT NOT NULL,
            tratamiento    TEXT NOT NULL,
            severidad      TEXT NOT NULL,
            embedding_json TEXT NOT NULL DEFAULT '[]',
            PRIMARY KEY (cultivo, id)
          )
        ''');

        await db.execute('''
          CREATE TABLE knowledge_packages (
            cultivo         TEXT PRIMARY KEY,
            version         TEXT NOT NULL,
            embedding_model TEXT NOT NULL,
            embedding_dim   INTEGER NOT NULL,
            installed_at    TEXT NOT NULL
          )
        ''');
      },
    );
  }

  @override
  Future<TreatmentEntry?> querySQL(String cultivo, String id) async {
    final db = await _database;
    // LOWER() en cultivo para tolerar diferencias de capitalización entre lo
    // descargado ("Tomate") y lo buscado ("tomate" vía cultivoSlug).
    final rows = await db.rawQuery(
      'SELECT * FROM knowledge_fichas'
      ' WHERE LOWER(cultivo) = LOWER(?) AND id = ? LIMIT 1',
      [cultivo, id],
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<List<ScoredEntry>> vectorSearch({
    required String cultivo,
    required List<double> queryVector,
    required int topK,
  }) async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT * FROM knowledge_fichas WHERE LOWER(cultivo) = LOWER(?)',
      [cultivo],
    );

    final scored =
        rows
            .map(_fromRow)
            .map(
              (ficha) => ScoredEntry(
                ficha: ficha,
                score: cosineSimilarity(queryVector, ficha.embedding),
              ),
            )
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(topK).toList();
  }

  @override
  Future<void> insertPackage(Map<String, dynamic> json) async {
    final cultivo = json['cultivo'] as String?;
    final fichas = json['fichas'] as List?;

    // Caso límite (sección 10): paquete parcialmente corrupto o descarga
    // interrumpida. Se rechaza sin tocar el índice existente de ese cultivo;
    // el llamador debe seguir tratándolo como `packageMissing`.
    if (cultivo == null ||
        cultivo.isEmpty ||
        fichas == null ||
        fichas.isEmpty) {
      throw ArgumentError(
        'Paquete offline inválido: falta "cultivo" o "fichas" está vacío.',
      );
    }

    final db = await _database;
    await db.transaction((txn) async {
      // Al descargar una nueva versión, se reemplaza completamente el
      // índice anterior de ese cultivo (sección 10).
      await txn.delete(
        'knowledge_fichas',
        where: 'cultivo = ?',
        whereArgs: [cultivo],
      );

      for (final raw in fichas) {
        final ficha = raw as Map<String, dynamic>;
        await txn.insert('knowledge_fichas', {
          'cultivo': cultivo,
          'id': ficha['id'] as String,
          'enfermedad': ficha['enfermedad'] as String? ?? '',
          'sintomas': ficha['sintomas'] as String? ?? '',
          'tratamiento': ficha['tratamiento'] as String? ?? '',
          'severidad': ficha['severidad'] as String? ?? '',
          'embedding_json': jsonEncode(ficha['embedding'] ?? const []),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await txn.insert('knowledge_packages', {
        'cultivo': cultivo,
        'version': json['version'] as String? ?? '',
        'embedding_model': json['embedding_model'] as String? ?? '',
        'embedding_dim': json['embedding_dim'] as int? ?? 0,
        'installed_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<bool> hasPackage(String cultivo) async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT 1 FROM knowledge_packages WHERE LOWER(cultivo) = LOWER(?) LIMIT 1',
      [cultivo],
    );
    return rows.isNotEmpty;
  }

  TreatmentEntry _fromRow(Map<String, Object?> row) {
    final embeddingRaw = jsonDecode(row['embedding_json'] as String? ?? '[]');
    return TreatmentEntry(
      id: row['id'] as String,
      cultivo: row['cultivo'] as String,
      enfermedad: row['enfermedad'] as String,
      sintomas: row['sintomas'] as String,
      tratamiento: row['tratamiento'] as String,
      severidad: row['severidad'] as String,
      embedding: (embeddingRaw as List)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}
