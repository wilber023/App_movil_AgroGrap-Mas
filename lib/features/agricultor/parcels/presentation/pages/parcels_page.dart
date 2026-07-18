import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/parcel_entity.dart';
import '../bloc/parcel_bloc.dart';
import '../widgets/add_parcel_dashed_button.dart';
import '../widgets/parcel_list_card.dart';
import '../widgets/parcels_empty_state.dart';
import '../widgets/parcels_error_state.dart';
import '../widgets/parcels_search_bar.dart';
import 'add_parcel_page.dart';

// =============================================================================
// AgroGraph-MAS -- Mis Parcelas (lista principal)
// =============================================================================

class ParcelsPage extends StatelessWidget {
  const ParcelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ParcelsView();
  }
}

class _ParcelsView extends StatelessWidget {
  const _ParcelsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parcelsBg,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_outlined, color: AppColors.onPrimary),
          onPressed: () {},
        ),
        title: Text(
          'Mis Parcelas',
          style: AppTypography.labelMd.copyWith(
            color: AppColors.onPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_outlined,
              color: AppColors.warmAmber,
              size: 22,
            ),
            onPressed: () => _openAddParcel(context),
          ),
        ],
      ),
      body: BlocConsumer<ParcelBloc, ParcelState>(
        listener: (context, state) {
          if (state is ParcelDeleted) {
            context.read<ParcelBloc>().add(const ParcelLoadRequested());
          }
          if (state is ParcelFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.burntOrange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ParcelLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.forestGreen),
            );
          }
          if (state is ParcelLoaded) {
            if (state.parcels.isEmpty) {
              return ParcelsEmptyState(onAddParcel: () => _openAddParcel(context));
            }
            return _buildParcelList(context, state.parcels);
          }
          if (state is ParcelFailure) {
            return ParcelsErrorState(message: state.message);
          }
          return const Center(
            child: CircularProgressIndicator(color: AppColors.forestGreen),
          );
        },
      ),
    );
  }

  void _openAddParcel(BuildContext context) async {
    final bloc = context.read<ParcelBloc>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddParcelPage()),
    );
    bloc.add(const ParcelLoadRequested());
  }

  Widget _buildParcelList(BuildContext context, List<ParcelEntity> parcels) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.lg, AppSpacing.xxlPlus, AppSpacing.none),
            child: const ParcelsSearchBar(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus),
            child: Column(
              children: [
                for (int i = 0; i < parcels.length; i++) ...[
                  ParcelListCard(parcel: parcels[i]),
                  if (i < parcels.length - 1) const SizedBox(height: AppSpacing.lg),
                ],
                const SizedBox(height: AppSpacing.lg),
                AddParcelDashedButton(onTap: () => _openAddParcel(context)),
                const SizedBox(height: AppSpacing.giant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
