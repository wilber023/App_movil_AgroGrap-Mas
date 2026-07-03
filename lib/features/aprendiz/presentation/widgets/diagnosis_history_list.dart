import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../agricultor/diagnosis/domain/entities/diagnosis_entity.dart';
import '../bloc/aprendiz_diagnosis_history_cubit.dart';
import '../pages/diagnosis_result_aprendiz_page.dart';
import 'diagnosis_history_card.dart';

const String _kFont = 'Inter';

/// Contenido de la pestaña "Mis diagnósticos": escucha
/// [AprendizDiagnosisHistoryCubit] (ya provisto por un ancestro) y renderiza
/// loading / error / vacío / lista, delegando cada fila a [DiagnosisHistoryCard].
class DiagnosisHistoryList extends StatelessWidget {
  const DiagnosisHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AprendizDiagnosisHistoryCubit, AprendizDiagnosisHistoryState>(
      builder: (context, state) {
        if (state is AprendizDiagnosisHistoryLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.aSecondary));
        }

        if (state is AprendizDiagnosisHistoryError) {
          return _ErrorState(message: state.message);
        }

        final diagnoses = state is AprendizDiagnosisHistoryLoaded ? state.diagnoses : <DiagnosisEntity>[];

        if (diagnoses.isEmpty) {
          return const _EmptyState();
        }

        return RefreshIndicator(
          color: AppColors.aSecondary,
          onRefresh: () => context.read<AprendizDiagnosisHistoryCubit>().loadHistory(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 80),
            itemCount: diagnoses.length,
            itemBuilder: (context, index) {
              final d = diagnoses[index];
              return DiagnosisHistoryCard(
                diagnosis: d,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DiagnosisResultAprendizPage(diagnosis: d, activityId: ''),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
              color: AppColors.aSecondaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_outlined, size: 38, color: AppColors.aSecondary),
          ),
          const SizedBox(height: 18),
          const Text(
            'Sin diagnósticos aún',
            style: TextStyle(fontFamily: _kFont, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.aOnSurface),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tus diagnósticos anteriores\naparecerán aquí.',
            style: TextStyle(fontFamily: _kFont, fontSize: 14, color: AppColors.aOnSurfaceVariant, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: _kFont, color: AppColors.aOnSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.read<AprendizDiagnosisHistoryCubit>().loadHistory(),
              child: const Text('Reintentar', style: TextStyle(fontFamily: _kFont, color: AppColors.aSecondary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
