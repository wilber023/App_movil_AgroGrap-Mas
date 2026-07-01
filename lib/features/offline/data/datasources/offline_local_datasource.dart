import 'package:path/path.dart' as path_pkg;
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/offline_document_entity.dart';
import '../models/offline_document_model.dart';

// =============================================================================
// INTERFACE
// PUNTO DE INTEGRACIÓN LLM/RAG:
//   - getCatalog()       → reemplazar con GET /api/v1/offline/catalog
//   - downloadDocument() → reemplazar con GET /api/v1/offline/documents/{id}
//     El equipo LLM debe devolver: content + embedding_json (float[])
// =============================================================================

abstract interface class OfflineLocalDataSource {
  Future<bool> getOfflineModeEnabled();
  Future<void> setOfflineModeEnabled(bool enabled);
  Future<DateTime?> getLastSyncAt();
  Future<void> setLastSyncAt(DateTime dt);
  Future<List<OfflineDocumentModel>> getCatalog();
  Future<void> setDocumentStatus(
    String docId,
    String status, {
    DateTime? downloadedAt,
    int? sizeBytes,
  });
  Future<int> getTotalUsedBytes();
  Future<void> deleteDocument(String docId);
}

// =============================================================================
// IMPLEMENTACIÓN — SQLite
// =============================================================================

class OfflineLocalDataSourceImpl implements OfflineLocalDataSource {
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
    final dbPath = path_pkg.join(dbsPath, 'agro_offline.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedCatalog(db);
      },
      onOpen: (db) async {
        // Re-seed si el catálogo fue borrado accidentalmente
        final count = Sqflite.firstIntValue(
              await db.rawQuery(
                  'SELECT COUNT(*) FROM offline_documents'),
            ) ??
            0;
        if (count == 0) await _seedCatalog(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // Documentos fitosanitarios (catálogo + estado de descarga)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_documents (
        id           TEXT PRIMARY KEY,
        crop_name    TEXT NOT NULL,
        disease_name TEXT NOT NULL,
        title        TEXT NOT NULL,
        content      TEXT NOT NULL,
        source       TEXT NOT NULL,
        embedding_json TEXT DEFAULT '[]',
        size_bytes   INTEGER NOT NULL DEFAULT 0,
        status       TEXT NOT NULL DEFAULT 'available',
        downloaded_at TEXT,
        version      TEXT NOT NULL DEFAULT '1.0',
        created_at   TEXT NOT NULL
      )
    ''');

    // Configuración de modo offline + última sincronización
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_status (
        id                INTEGER PRIMARY KEY,
        is_offline_mode   INTEGER NOT NULL DEFAULT 0,
        last_sync_at      TEXT,
        last_modified     TEXT NOT NULL
      )
    ''');

    // Chunks de texto para retrieval local (RAG offline)
    // PUNTO DE INTEGRACIÓN: el equipo LLM popula esta tabla con chunks
    // reales del corpus al descargar cada documento.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_indexes (
        id             TEXT PRIMARY KEY,
        document_id    TEXT NOT NULL,
        chunk_index    INTEGER NOT NULL,
        chunk_text     TEXT NOT NULL,
        embedding_json TEXT DEFAULT '[]',
        created_at     TEXT NOT NULL,
        FOREIGN KEY (document_id)
          REFERENCES offline_documents(id) ON DELETE CASCADE
      )
    ''');

    // Cola de descargas pendientes
    await db.execute('''
      CREATE TABLE IF NOT EXISTS download_queue (
        id            TEXT PRIMARY KEY,
        document_id   TEXT NOT NULL,
        progress      REAL NOT NULL DEFAULT 0.0,
        status        TEXT NOT NULL DEFAULT 'queued',
        error_message TEXT,
        created_at    TEXT NOT NULL,
        FOREIGN KEY (document_id)
          REFERENCES offline_documents(id) ON DELETE CASCADE
      )
    ''');

    // Fila única de configuración global
    await db.insert('sync_status', {
      'id': 1,
      'is_offline_mode': 0,
      'last_sync_at': null,
      'last_modified': DateTime.now().toIso8601String(),
    });
  }

  // ---------------------------------------------------------------------------
  // Catálogo mock — reemplazar por endpoint real cuando esté disponible
  // PUNTO DE INTEGRACIÓN: GET /api/v1/offline/catalog
  // ---------------------------------------------------------------------------
  Future<void> _seedCatalog(Database db) async {
    final now = DateTime.now();
    for (final doc in _mockCatalog(now)) {
      await db.insert(
        'offline_documents',
        doc.toRow(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  static List<OfflineDocumentModel> _mockCatalog(DateTime now) => [
        // 🍅 Tomate
        OfflineDocumentModel(
          id: 'doc_tomato_lateblight',
          cropName: 'Tomate',
          diseaseName: 'Tizón tardío',
          title: 'Control de Phytophthora infestans en tomate',
          content:
              'Phytophthora infestans es el oomiceto causante del tizón tardío del tomate. '
              'Se caracteriza por lesiones necróticas con halo acuoso y micelio blanco en el envés. '
              'Tratamiento: mancozeb 80% (2.5 g/L) + metalaxil (1 g/L), aplicar cada 7 días. '
              'Condiciones de riesgo: humedad relativa > 90%, temperatura 10–25 °C.',
          source: 'FAO-2023',
          sizeBytes: 148 * 1024,
          status: OfflineDocumentStatus.available,
          version: '2.1',
          createdAt: now,
        ),
        OfflineDocumentModel(
          id: 'doc_tomato_earlyblight',
          cropName: 'Tomate',
          diseaseName: 'Tizón temprano',
          title: 'Manejo integrado de Alternaria solani en tomate',
          content:
              'Alternaria solani produce manchas concéntricas oscuras con halo amarillo. '
              'Inicia en hojas basales y avanza hacia arriba en condiciones cálidas. '
              'Tratamiento: clorotalonil 75% (2 g/L), mancozeb o azoxistrobina. '
              'Rotación de cultivos por 2 temporadas. Eliminar restos de cosecha.',
          source: 'INIFAP-2022',
          sizeBytes: 112 * 1024,
          status: OfflineDocumentStatus.available,
          version: '1.3',
          createdAt: now,
        ),
        OfflineDocumentModel(
          id: 'doc_tomato_mosaic',
          cropName: 'Tomate',
          diseaseName: 'Virus del mosaico',
          title: 'Potato Virus Y en solanáceas: identificación y control',
          content:
              'El PVY causa mosaico, clorosis y necrosis en tejidos de tomate. '
              'Transmisión por pulgones (Myzus persicae). No existe cura viral. '
              'Control: eliminar plantas infectadas, controlar vectores con imidacloprid. '
              'Usar semilla certificada libre de virus. Desinfectar herramientas.',
          source: 'INIA-España-2021',
          sizeBytes: 98 * 1024,
          status: OfflineDocumentStatus.available,
          version: '1.0',
          createdAt: now,
        ),
        // 🌽 Maíz
        OfflineDocumentModel(
          id: 'doc_corn_rust',
          cropName: 'Maíz',
          diseaseName: 'Roya común',
          title: 'Protocolo fitosanitario para Puccinia sorghi en maíz',
          content:
              'Puccinia sorghi forma pústulas anaranjadas en ambas superficies foliares. '
              'Favorecida por temperaturas de 15–25 °C y alta humedad. '
              'Tratamiento: propiconazol (0.5 mL/L) o tebuconazol en estadio V6. '
              'Variedades resistentes disponibles: B73, NK603.',
          source: 'CIMMYT-2022',
          sizeBytes: 134 * 1024,
          status: OfflineDocumentStatus.available,
          version: '1.5',
          createdAt: now,
        ),
        OfflineDocumentModel(
          id: 'doc_corn_leafspot',
          cropName: 'Maíz',
          diseaseName: 'Mancha foliar gris',
          title: 'Cercospora zeae-maydis: manejo en campo',
          content:
              'Manchas rectangulares grises o marrones limitadas por nervaduras foliares. '
              'Favorecida por noches frías y días húmedos en maíz denso. '
              'Tratamiento: aplicar estrobilurinas (azoxistrobina 2 mL/L) en V10-VT. '
              'Reducir densidad de siembra y asegurar buena ventilación.',
          source: 'INIFAP-2023',
          sizeBytes: 89 * 1024,
          status: OfflineDocumentStatus.available,
          version: '1.1',
          createdAt: now,
        ),
        // 🥔 Papa
        OfflineDocumentModel(
          id: 'doc_potato_lateblight',
          cropName: 'Papa',
          diseaseName: 'Tizón tardío',
          title: 'Guía de control de Phytophthora infestans en papa',
          content:
              'En papa produce tizón en tubérculos. '
              'Estrategia preventiva: aplicar antes de lluvia con clorotalonil o mancozeb. '
              'Estrategia curativa: metalaxil + clorotalonil o dimetomorph. '
              'Monitorear mediante modelos BLITECAST o Simcast.',
          source: 'CIP-Lima-2023',
          sizeBytes: 165 * 1024,
          status: OfflineDocumentStatus.available,
          version: '3.0',
          createdAt: now,
        ),
        // 🫘 Frijol
        OfflineDocumentModel(
          id: 'doc_bean_anthracnose',
          cropName: 'Frijol',
          diseaseName: 'Antracnosis',
          title: 'Colletotrichum lindemuthianum en frijol: guía de campo',
          content:
              'Lesiones oscuras en vainas, tallos y hojas con centro rosado bajo humedad. '
              'Transmisión por semilla infectada y salpicadura de lluvia. '
              'Tratamiento: thiram 75% como tratamiento de semilla + mancozeb foliar. '
              'Usar variedades resistentes. Evitar riego por aspersión.',
          source: 'CIAT-2022',
          sizeBytes: 107 * 1024,
          status: OfflineDocumentStatus.available,
          version: '1.2',
          createdAt: now,
        ),
        // 🎃 Calabaza
        OfflineDocumentModel(
          id: 'doc_squash_powdery',
          cropName: 'Calabaza',
          diseaseName: 'Mildiú polvoroso',
          title: 'Podosphaera xanthii en cucurbitáceas: manejo integrado',
          content:
              'Podosphaera xanthii produce polvo blanco harinoso en hojas y tallos. '
              'Favorecido por días calurosos y noches frescas con baja humedad. '
              'Tratamiento: azufre micronizado (3 g/L) o myclobutanil. '
              'Eliminar hojas afectadas. Mejorar circulación de aire entre plantas.',
          source: 'FAO-2022',
          sizeBytes: 103 * 1024,
          status: OfflineDocumentStatus.available,
          version: '1.1',
          createdAt: now,
        ),
      ];

  // ---------------------------------------------------------------------------
  // Implementación de la interfaz
  // ---------------------------------------------------------------------------

  @override
  Future<bool> getOfflineModeEnabled() async {
    final db = await _database;
    final rows = await db.query('sync_status', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) return false;
    return (rows.first['is_offline_mode'] as int? ?? 0) == 1;
  }

  @override
  Future<void> setOfflineModeEnabled(bool enabled) async {
    final db = await _database;
    await db.update(
      'sync_status',
      {
        'is_offline_mode': enabled ? 1 : 0,
        'last_modified': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  @override
  Future<DateTime?> getLastSyncAt() async {
    final db = await _database;
    final rows = await db.query('sync_status', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) return null;
    final raw = rows.first['last_sync_at'] as String?;
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  @override
  Future<void> setLastSyncAt(DateTime dt) async {
    final db = await _database;
    await db.update(
      'sync_status',
      {'last_sync_at': dt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  @override
  Future<List<OfflineDocumentModel>> getCatalog() async {
    final db = await _database;
    final rows = await db.query(
      'offline_documents',
      orderBy: 'crop_name ASC, disease_name ASC',
    );
    return rows.map(OfflineDocumentModel.fromRow).toList();
  }

  @override
  Future<void> setDocumentStatus(
    String docId,
    String status, {
    DateTime? downloadedAt,
    int? sizeBytes,
  }) async {
    final db = await _database;
    final updates = <String, dynamic>{'status': status};
    if (downloadedAt != null) {
      updates['downloaded_at'] = downloadedAt.toIso8601String();
    }
    if (sizeBytes != null) {
      updates['size_bytes'] = sizeBytes;
    }
    await db.update(
      'offline_documents',
      updates,
      where: 'id = ?',
      whereArgs: [docId],
    );
  }

  @override
  Future<int> getTotalUsedBytes() async {
    final db = await _database;
    final result = await db.rawQuery(
      "SELECT SUM(size_bytes) as total FROM offline_documents WHERE status = 'downloaded'",
    );
    return (result.first['total'] as int?) ?? 0;
  }

  @override
  Future<void> deleteDocument(String docId) async {
    final db = await _database;
    await db.update(
      'offline_documents',
      {'status': 'available', 'downloaded_at': null},
      where: 'id = ?',
      whereArgs: [docId],
    );
    // También eliminar chunks del índice local
    await db.delete(
      'local_indexes',
      where: 'document_id = ?',
      whereArgs: [docId],
    );
  }
}
