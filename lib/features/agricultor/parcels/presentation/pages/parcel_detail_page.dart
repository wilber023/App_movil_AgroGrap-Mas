import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../diagnosis/presentation/bloc/diagnosis_bloc.dart';
import '../../../diagnosis/presentation/pages/diagnosis_page.dart';
import '../../domain/entities/parcel_entity.dart';
import '../widgets/parcel_detail_helpers.dart';
import '../widgets/parcel_diagnosis_history_tab.dart';
import '../widgets/parcel_resumen_tab.dart';

// =============================================================================
// AgroGraph-MAS -- Detalle de Parcela
// =============================================================================

class ParcelDetailPage extends StatelessWidget {
  final ParcelEntity parcel;

  const ParcelDetailPage({super.key, required this.parcel});

  @override
  Widget build(BuildContext context) {
    final emoji = parcelDetailEmoji(parcel.cropName);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.parcelsBg,
        appBar: AppBar(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_outlined, color: AppColors.onPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                parcel.name,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.onPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$emoji ${parcel.cropName}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.parcelsAppBarSubtitle,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            labelColor: AppColors.onPrimary,
            unselectedLabelColor: AppColors.parcelsAppBarSubtitle,
            indicatorColor: AppColors.warmAmber,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
            tabs: [
              Tab(text: 'Resumen'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ParcelResumenTab(parcel: parcel),
            BlocProvider(
              create: (_) => sl<DiagnosisBloc>()
                ..add(
                  DiagnosisParcelHistoryRequested(parcelId: parcel.seleccionId),
                ),
              child: ParcelDiagnosisHistoryTab(parcel: parcel),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _navigateToDiagnosis(context),
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.onPrimary,
          elevation: 3,
          icon: const Icon(Icons.camera_alt_outlined),
          label: Text(
            'Diagnosticar',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
    );
  }

  void _navigateToDiagnosis(BuildContext context) {
    // Limpia estado residual del bloc raíz antes de abrir la cámara
    context.read<DiagnosisBloc>().add(const DiagnosisReset());
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiagnosisPage(
          parcelId: parcel.seleccionId,
          parcelName: parcel.name,
        ),
      ),
    );
  }
}
