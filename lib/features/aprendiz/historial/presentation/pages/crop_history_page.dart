import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/crop_event_entity.dart';
import '../bloc/crop_history_bloc.dart';

final _mockEvents = [
  CropEventEntity(id: 'h1', type: CropEventType.siembra, title: 'Siembra', description: 'Maíz H-59 · 2.5 ha · Milpa Norte', date: DateTime(2026, 3, 15)),
  CropEventEntity(id: 'h2', type: CropEventType.inspeccionSinPatologia, title: 'Inspección', description: 'Sin patología detectada.', date: DateTime(2026, 3, 22)),
  CropEventEntity(id: 'h3', type: CropEventType.fertilizacion, title: 'Fertilización', description: 'Nitrógeno aplicado.', date: DateTime(2026, 4, 5)),
  CropEventEntity(id: 'h4', type: CropEventType.inspeccionSinPatologia, title: 'Inspección rutinaria', description: 'Revisión visual general.', date: DateTime(2026, 4, 19)),
  CropEventEntity(id: 'h5', type: CropEventType.deteccionEnfermedad, title: 'Detección de enfermedad', description: 'Tizón tardío detectado.', date: DateTime(2026, 4, 25)),
  CropEventEntity(id: 'h6', type: CropEventType.tratamientoAplicado, title: 'Tratamiento', description: 'Aplicación de Metalaxil.', date: DateTime(2026, 4, 26)),
  CropEventEntity(id: 'h7', type: CropEventType.mejoraObservada, title: 'Mejoría observada', description: 'Respuesta positiva al tratamiento.', date: DateTime(2026, 5, 3)),
  CropEventEntity(id: 'h8', type: CropEventType.inspeccionSinPatologia, title: 'Ciclo completado', description: 'Recuperación total.', date: DateTime(2026, 5, 10)),
  CropEventEntity(id: 'h9', type: CropEventType.inspeccionSinPatologia, title: 'Inspección post-tratamiento', description: 'Monitoreo preventivo.', date: DateTime(2026, 5, 17)),
  CropEventEntity(id: 'h10', type: CropEventType.actividadPospuesta, title: 'Pospuesto', description: 'Actividad pausada temporalmente.', date: DateTime(2026, 6, 6)),
];

class CropHistoryPage extends StatelessWidget {
  const CropHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CropHistoryBloc>()..loadHistory(),
      child: const _CropHistoryView(),
    );
  }
}

class _CropHistoryView extends StatelessWidget {
  const _CropHistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aSurface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              height: 56,
              color: AppColors.aPrimaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Mi historial',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: BlocBuilder<CropHistoryBloc, CropHistoryState>(
                builder: (context, state) {
                  if (state is CropHistoryLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.aSecondary));
                  }
                  final events = state is CropHistoryLoaded
                      ? state.history
                      : state is CropHistoryEmpty
                          ? <CropEventEntity>[]
                          : _mockEvents;

                  if (events.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72, height: 72,
                            decoration: const BoxDecoration(color: AppColors.aSurfaceContainer, shape: BoxShape.circle),
                            child: const Icon(Icons.history_outlined, size: 36, color: AppColors.aOnSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          const Text('Sin eventos aún', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.aOnSurface)),
                          const SizedBox(height: 8),
                          const Text('Aquí verás el historial de tu cultivo.', style: TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant)),
                        ],
                      ),
                    );
                  }

                  return _HistoryList(events: events);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<CropEventEntity> events;
  const _HistoryList({required this.events});

  String _fmtDate(DateTime d) {
    const m = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${d.day} ${m[d.month]}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: events.length + 1, // +1 for subtitle header
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Generado automáticamente con tu actividad.',
              style: TextStyle(fontSize: 13, color: AppColors.aOnSurfaceVariant),
            ),
          );
        }
        final event = events[index - 1];
        final isCritical = event.type == CropEventType.deteccionEnfermedad;

        return _HistoryRow(event: event, isCritical: isCritical, dateStr: _fmtDate(event.date));
      },
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final CropEventEntity event;
  final bool isCritical;
  final String dateStr;

  const _HistoryRow({required this.event, required this.isCritical, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    final iconColor = _iconColor(event.type);
    final iconBg = _iconBg(event.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isCritical ? AppColors.aDiseaseCardBg : AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCritical ? AppColors.aDiseaseCardBorder : AppColors.aOutlineVariant,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(event.type.icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCritical ? AppColors.aDiseaseCardText : AppColors.aOnSurface,
                  ),
                ),
                if (event.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCritical
                            ? AppColors.aDiseaseCardText.withValues(alpha: 0.75)
                            : AppColors.aOnSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.aOnSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _iconBg(CropEventType type) => switch (type) {
    CropEventType.siembra || CropEventType.inspeccionSinPatologia || CropEventType.mejoraObservada =>
      AppColors.aSecondaryContainer,
    CropEventType.fertilizacion => const Color(0xFFBBDEFB),
    CropEventType.deteccionEnfermedad => AppColors.errorContainer,
    CropEventType.tratamientoAplicado => AppColors.aTertiaryFixed,
    CropEventType.actividadPospuesta => AppColors.aSurfaceContainerHigh,
  };

  Color _iconColor(CropEventType type) => switch (type) {
    CropEventType.siembra || CropEventType.inspeccionSinPatologia || CropEventType.mejoraObservada =>
      AppColors.aSecondary,
    CropEventType.fertilizacion => const Color(0xFF1565C0),
    CropEventType.deteccionEnfermedad => AppColors.error,
    CropEventType.tratamientoAplicado => AppColors.aOnTertiaryFixedVariant,
    CropEventType.actividadPospuesta => AppColors.aOnSurfaceVariant,
  };
}
