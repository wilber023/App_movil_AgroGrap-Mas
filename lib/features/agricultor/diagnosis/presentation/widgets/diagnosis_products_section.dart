import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../cubit/product_recommendation_cubit.dart';
import 'product_card.dart';
import 'products_skeleton_loader.dart';

/// Sección "Productos recomendados" de [DiagnosisResultPage]: escucha
/// [ProductRecommendationCubit] y renderiza skeleton / error / vacío / lista
/// de [ProductCard] según el estado.
class DiagnosisProductsSection extends StatelessWidget {
  const DiagnosisProductsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductRecommendationCubit, ProductRecommendationState>(
      builder: (context, state) {
        if (state is ProductRecommendationIdle) {
          return const SizedBox.shrink();
        }
        if (state is ProductRecommendationLoading) {
          return const ProductsSkeletonLoader();
        }
        if (state is ProductRecommendationError) {
          return _buildStatusCard(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.diagnosisInsecticida,
            text: 'No fue posible cargar recomendaciones.',
          );
        }
        if (state is ProductRecommendationLoaded && state.products.isEmpty) {
          return _buildStatusCard(
            icon: Icons.search_off_rounded,
            iconColor: AppColors.parcelsTextSecondary,
            text: 'No se encontraron productos para esta enfermedad.',
          );
        }
        if (state is ProductRecommendationLoaded) {
          return _buildLoaded(state);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.onPrimary,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.parcelsTrackGrey, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.parcelsTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded(ProductRecommendationLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de sección
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.none, AppSpacing.xxl, AppSpacing.xxl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Productos recomendados',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.parcelsTextPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Ordenados por costo-beneficio',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.parcelsTextSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Ver todos',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forestGreen,
                ),
              ),
            ],
          ),
        ),
        // Tarjetas de productos
        ...state.products.asMap().entries.map(
          (e) => ProductCard(product: e.value, index: e.key),
        ),
      ],
    );
  }
}
