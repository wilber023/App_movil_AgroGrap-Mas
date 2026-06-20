import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/crop_event_entity.dart';
import '../bloc/crop_history_bloc.dart';

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header simple
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mi historial', style: AppTypography.tituloLg),
                        const SizedBox(height: 4),
                        Text(
                          'Generado automáticamente con tu actividad.',
                          style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido
            Expanded(
              child: BlocBuilder<CropHistoryBloc, CropHistoryState>(
                builder: (context, state) {
                  if (state is CropHistoryLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.forestGreen));
                  }
                  
                  if (state is CropHistoryError) {
                    return Center(
                      child: Text(state.message, style: AppTypography.bodyMd.copyWith(color: AppColors.error)),
                    );
                  }
                  
                  if (state is CropHistoryEmpty) {
                    return _buildEmptyState();
                  }
                  
                  if (state is CropHistoryLoaded) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: state.history.length,
                      itemBuilder: (context, index) {
                        final isLast = index == state.history.length - 1;
                        return _buildTimelineItem(state.history[index], isLast);
                      },
                    );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.surfaceVariant,
              child: const Icon(Icons.schedule_rounded, size: 40, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Text(
              'Aún no tienes eventos registrados.',
              style: AppTypography.tituloMd.copyWith(color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Aparecerán aquí conforme avances en tu plan de cultivo.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(CropEventEntity event, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: event.type.backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(event.type.icon, color: event.type.iconColor, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.surfaceVariant,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(event.title, style: AppTypography.etiquetaBold.copyWith(color: AppColors.onSurface)),
                      ),
                      Text(
                        _formatDate(event.date),
                        style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
