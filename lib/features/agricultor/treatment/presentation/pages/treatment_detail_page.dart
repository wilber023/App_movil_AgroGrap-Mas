// =============================================================================
// Feature: Treatment -- Detalle del Tratamiento
// =============================================================================
// Capa: Presentation / Pages
// Pantalla nueva de solo lectura + acciones ya existentes (marcar paso
// completo / reprogramar). No agrega Bloc, Repository, Datasource ni
// UseCases: reutiliza el mismo TreatmentBloc ya provisto en main.dart y los
// mismos eventos que ya usa la vista de lista (treatment_page.dart).
//
// Recibe el TreatmentEntity ya cargado (evita una llamada de red/Hive
// adicional) y se subscribe al TreatmentBloc para mantenerse actualizada:
// si el usuario marca un paso completo o reprograma desde aqui, el Bloc
// recarga la agenda completa (igual que ya hacia antes) y esta pantalla
// vuelve a leer el tratamiento actualizado por id desde el nuevo estado.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/treatment_entity.dart';
import '../bloc/treatment_bloc.dart';
import '../widgets/treatment_detail_action_bar.dart';
import '../widgets/treatment_detail_header_card.dart';
import '../widgets/treatment_detail_step_card.dart';

// =============================================================================
// Pantalla
// =============================================================================

class TreatmentDetailPage extends StatelessWidget {
  final TreatmentEntity treatment;
  const TreatmentDetailPage({super.key, required this.treatment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        title: Text(
          'Detalle del tratamiento',
          style: AppTypography.labelMd.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.xxlPlus),
            child: Icon(Icons.eco_rounded, color: AppColors.forestGreen),
          ),
        ],
      ),
      body: BlocBuilder<TreatmentBloc, TreatmentState>(
        builder: (context, state) {
          // Si el Bloc ya recargo la agenda (ej. tras marcar un paso
          // completo desde esta misma pantalla), se usa la version mas
          // fresca del mismo tratamiento; si no, se usa la que llego por
          // parametro al navegar aqui.
          //
          // Nota: se evita firstWhere(orElse:) a proposito. La lista real
          // detras de `state.treatments` es un List<TreatmentModel> (el
          // subtipo que arma el datasource), aunque el campo este tipado
          // como List<TreatmentEntity>. En Dart, firstWhere() usa el tipo
          // generico real de la lista en tiempo de ejecucion, asi que un
          // `orElse: () => treatment` (tipado TreatmentEntity) lanza
          // TypeError en runtime pese a compilar sin errores. Un bucle
          // manual no tiene ese problema.
          TreatmentEntity current = treatment;
          if (state is TreatmentAgendaLoaded) {
            for (final t in state.treatments) {
              if (t.id == treatment.id) {
                current = t;
                break;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.xxlPlus, AppSpacing.xxlPlus, AppSpacing.xhuge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TreatmentDetailHeaderCard(treatment: current),
                const SizedBox(height: AppSpacing.hugePlus),
                Text(
                  'Plan de tratamiento',
                  style: AppTypography.tituloMd.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                for (int i = 0; i < current.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    child: TreatmentDetailStepCard(
                      step: current.steps[i],
                      isLast: i == current.steps.length - 1,
                      isImmediateNext: _isImmediateNext(current, i),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                TreatmentDetailActionBar(treatment: current),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Puramente de presentacion: el paso "próximo" es el inmediatamente
  /// siguiente al activo en el orden ya existente de la lista, no un campo
  /// nuevo del dominio.
  bool _isImmediateNext(TreatmentEntity t, int index) {
    final activeIndex = t.steps.indexWhere((s) => s.isScheduled);
    if (activeIndex == -1) return false;
    return index == activeIndex + 1;
  }
}
