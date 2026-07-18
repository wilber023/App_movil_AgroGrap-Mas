import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../diagnosis/presentation/bloc/diagnosis_bloc.dart';
import '../../../diagnosis/presentation/pages/diagnosis_result_page.dart';
import '../../domain/entities/parcel_entity.dart';
import 'parcel_diagnosis_history_card.dart';

/// Pestaña "Historial" de [ParcelDetailPage]: lista de diagnósticos ya
/// filtrada por parcela (el filtro lo aplica el `DiagnosisBloc` provisto
/// por la página, vía `DiagnosisParcelHistoryRequested`).
class ParcelDiagnosisHistoryTab extends StatelessWidget {
  final ParcelEntity parcel;

  const ParcelDiagnosisHistoryTab({super.key, required this.parcel});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiagnosisBloc, DiagnosisState>(
      builder: (context, state) {
        if (state is DiagnosisHistoryLoaded) {
          if (state.filteredItems.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.behemoth),
            itemCount: state.filteredItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
            itemBuilder: (context, i) {
              final dx = state.filteredItems[i];
              return ParcelDiagnosisHistoryCard(
                diagnosis: dx,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiagnosisResultPage(diagnosis: dx),
                  ),
                ),
              );
            },
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: AppColors.forestGreen),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.giant),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.parcelsChipGreenBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.forestGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.xxlPlus),
            Text(
              'Sin diagnósticos para esta parcela',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.parcelsTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Usa el botón "Diagnosticar" para analizar el cultivo con el modelo CNN.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.parcelsTextSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
