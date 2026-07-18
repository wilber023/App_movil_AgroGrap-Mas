import '../../domain/entities/offline_document_entity.dart';

/// Catálogo estático de guías offline — disponible sin SQLite, usado como
/// fallback por [OfflineCubit] cuando el catálogo real no está disponible.
///
/// PUNTO DE INTEGRACIÓN: reemplazar por endpoint real cuando esté disponible.
List<OfflineDocumentEntity> buildOfflineStaticCatalog() {
  final now = DateTime.now();
  return [
    // 🍅 Tomate
    OfflineDocumentEntity(id: 'doc_tomato_lateblight', cropName: 'Tomate', diseaseName: 'Tizón tardío', title: 'Control de Phytophthora infestans en tomate', content: '', source: 'FAO-2023', sizeBytes: 148 * 1024, status: OfflineDocumentStatus.available, version: '2.1', createdAt: now),
    OfflineDocumentEntity(id: 'doc_tomato_earlyblight', cropName: 'Tomate', diseaseName: 'Tizón temprano', title: 'Manejo integrado de Alternaria solani en tomate', content: '', source: 'INIFAP-2022', sizeBytes: 112 * 1024, status: OfflineDocumentStatus.available, version: '1.3', createdAt: now),
    OfflineDocumentEntity(id: 'doc_tomato_mosaic', cropName: 'Tomate', diseaseName: 'Virus del mosaico', title: 'Potato Virus Y en solanáceas', content: '', source: 'INIA-España-2021', sizeBytes: 98 * 1024, status: OfflineDocumentStatus.available, version: '1.0', createdAt: now),
    // 🌽 Maíz
    OfflineDocumentEntity(id: 'doc_corn_rust', cropName: 'Maíz', diseaseName: 'Roya común', title: 'Protocolo fitosanitario para Puccinia sorghi', content: '', source: 'CIMMYT-2022', sizeBytes: 134 * 1024, status: OfflineDocumentStatus.available, version: '1.5', createdAt: now),
    OfflineDocumentEntity(id: 'doc_corn_leafspot', cropName: 'Maíz', diseaseName: 'Mancha foliar gris', title: 'Cercospora zeae-maydis: manejo en campo', content: '', source: 'INIFAP-2023', sizeBytes: 89 * 1024, status: OfflineDocumentStatus.available, version: '1.1', createdAt: now),
    // 🥔 Papa
    OfflineDocumentEntity(id: 'doc_potato_lateblight', cropName: 'Papa', diseaseName: 'Tizón tardío', title: 'Guía de control de Phytophthora infestans en papa', content: '', source: 'CIP-Lima-2023', sizeBytes: 165 * 1024, status: OfflineDocumentStatus.available, version: '3.0', createdAt: now),
    // 🫘 Frijol
    OfflineDocumentEntity(id: 'doc_bean_anthracnose', cropName: 'Frijol', diseaseName: 'Antracnosis', title: 'Colletotrichum lindemuthianum en frijol', content: '', source: 'CIAT-2022', sizeBytes: 107 * 1024, status: OfflineDocumentStatus.available, version: '1.2', createdAt: now),
    // 🎃 Calabaza
    OfflineDocumentEntity(id: 'doc_squash_powdery', cropName: 'Calabaza', diseaseName: 'Mildiú polvoroso', title: 'Podosphaera xanthii en cucurbitáceas: manejo integrado', content: '', source: 'FAO-2022', sizeBytes: 103 * 1024, status: OfflineDocumentStatus.available, version: '1.1', createdAt: now),
  ];
}
