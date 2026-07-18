import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../cubit/epidemiological_map_cubit.dart';
import '../widgets/estado_resumen_tile.dart';

/// Mapa epidemiológico (clustering de campañas SENASICA por estado).
///
/// Pantalla compartida entre Agricultor y Aprendiz -- mismo componente,
/// misma lógica, sin duplicar nada por perfil.
class EpidemiologicalMapPage extends StatelessWidget {
  const EpidemiologicalMapPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => sl<EpidemiologicalMapCubit>()..load(),
        child: const EpidemiologicalMapPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mapa epidemiológico',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      body: BlocBuilder<EpidemiologicalMapCubit, EpidemiologicalMapState>(
        builder: (context, state) {
          if (state is EpidemiologicalMapInitial || state is EpidemiologicalMapLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.forestGreen));
          }
          if (state is EpidemiologicalMapError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<EpidemiologicalMapCubit>().load(),
            );
          }
          final mapa = (state as EpidemiologicalMapLoaded).mapa;
          if (mapa.estados.isEmpty) {
            return Center(
              child: Text(
                'No hay campañas registradas todavía.',
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxlPlus),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus),
                child: Text(
                  '${mapa.totalCampanias} campañas activas en ${mapa.estados.length} estados',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ...mapa.estados.map((e) => EstadoResumenTile(estado: e)),
            ],
          );
        },
      ),
    );
  }
}
