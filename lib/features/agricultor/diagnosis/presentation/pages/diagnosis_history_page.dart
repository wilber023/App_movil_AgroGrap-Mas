import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../bloc/diagnosis_bloc.dart';
import '../widgets/diagnosis_history_card.dart';
import '../widgets/diagnosis_history_empty_state.dart';
import '../widgets/diagnosis_history_filter_bar.dart';
import '../widgets/diagnosis_history_grouped_list.dart';

// =============================================================================
// AgroGraph-MAS -- Historial de Diagnosticos
// =============================================================================

// =============================================================================
// Bottom sheet version (invoked from camera history button)
// =============================================================================
class DiagnosisHistorySheet extends StatefulWidget {
  final ScrollController scrollController;

  const DiagnosisHistorySheet({super.key, required this.scrollController});

  @override
  State<DiagnosisHistorySheet> createState() => _DiagnosisHistorySheetState();
}

class _DiagnosisHistorySheetState extends State<DiagnosisHistorySheet> {
  @override
  void initState() {
    super.initState();
    context.read<DiagnosisBloc>().add(const DiagnosisHistoryRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxlPlus)),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.parcelsTrackGrey,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historial de diagnósticos',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.parcelsTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DiagnosisHistoryFullPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Ver todo',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 0.5, color: AppColors.parcelsBorderLight.withValues(alpha: 0.2)),
          // List
          Expanded(
            child: BlocBuilder<DiagnosisBloc, DiagnosisState>(
              builder: (context, state) {
                if (state is DiagnosisHistoryLoaded) {
                  final items = state.filteredItems;
                  if (items.isEmpty) {
                    return const DiagnosisHistoryEmptyState();
                  }
                  return ListView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    itemCount: items.length,
                    itemBuilder: (context, i) => DiagnosisHistoryCard(diagnosis: items[i]),
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.forestGreen,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Full screen version
// =============================================================================
class DiagnosisHistoryFullPage extends StatefulWidget {
  const DiagnosisHistoryFullPage({super.key});

  @override
  State<DiagnosisHistoryFullPage> createState() =>
      _DiagnosisHistoryFullPageState();
}

class _DiagnosisHistoryFullPageState extends State<DiagnosisHistoryFullPage> {
  static const List<String> _filters = [
    'Todos',
    'Con alerta',
    'En tratamiento',
    'Saludable',
  ];

  @override
  void initState() {
    super.initState();
    context.read<DiagnosisBloc>().add(const DiagnosisHistoryRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parcelsBg,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Historial de diagnósticos',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      body: BlocBuilder<DiagnosisBloc, DiagnosisState>(
        builder: (context, state) {
          if (state is DiagnosisHistoryLoaded) {
            return Column(
              children: [
                DiagnosisHistoryFilterBar(
                  filters: _filters,
                  activeFilter: state.activeFilter,
                  onFilterSelected: (filterName) => context
                      .read<DiagnosisBloc>()
                      .add(DiagnosisFilterHistory(filterName)),
                ),
                Expanded(
                  child: state.filteredItems.isEmpty
                      ? DiagnosisHistoryEmptyState(
                          onGoToCamera: () => Navigator.pop(context),
                        )
                      : DiagnosisHistoryGroupedList(items: state.filteredItems),
                ),
              ],
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: AppColors.forestGreen),
          );
        },
      ),
    );
  }
}
