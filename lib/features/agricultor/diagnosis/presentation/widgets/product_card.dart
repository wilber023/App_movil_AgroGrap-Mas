import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/product_entity.dart';
import 'product_badge_chip.dart';

/// Tarjeta de producto recomendado — diseño compacto horizontal, usada en
/// la sección "Productos recomendados" de [DiagnosisResultPage].
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.index});

  final ProductEntity product;
  final int index;

  static const _kFungicida = AppColors.diagnosisCompletedBadge;
  static const _kInsecticida = AppColors.diagnosisInsecticida;
  static const _kHerbicida = AppColors.diagnosisHerbicida;
  static const _kFertilizante = AppColors.diagnosisFertilizante;
  static const _kBiologico = AppColors.diagnosisBiologico;
  static const _kOther = AppColors.diagnosisOtherProduct;

  Color get _typeColor => switch (product.productType?.toLowerCase()) {
    'fungicida' => _kFungicida,
    'insecticida' => _kInsecticida,
    'herbicida' => _kHerbicida,
    'fertilizante' => _kFertilizante,
    'biológico' || 'biologico' => _kBiologico,
    _ => _kOther,
  };

  double get _efficacy {
    if (product.rating != null) {
      return (product.rating! / 5.0).clamp(0.0, 1.0);
    }
    const fallbacks = [0.88, 0.82, 0.76, 0.70];
    return fallbacks[math.min(index, fallbacks.length - 1)];
  }

  // Devuelve (etiqueta, color, descripción) del badge
  ({String label, Color color, String desc})? get _badge {
    final type = product.productType?.toLowerCase() ?? '';
    if (type == 'biológico' || type == 'biologico') {
      return (
        label: 'ECOLÓGICO',
        color: AppColors.diagnosisEcoBadge,
        desc: 'Mejora la salud del suelo y la planta.',
      );
    }
    if (index == 0) {
      return (
        label: 'MEJOR OPCIÓN',
        color: AppColors.forestGreen,
        desc: 'Excelente efecto prolongado.',
      );
    }
    return (
      label: 'MÁS ECONÓMICO',
      color: AppColors.diagnosisEconomicBadge,
      desc: 'Alternativa preventiva de amplio espectro.',
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    final eff = _efficacy;
    final effPct = (eff * 100).round();
    final typeStr = product.productType != null
        ? product.productType![0].toUpperCase() +
              product.productType!.substring(1)
        : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.none, AppSpacing.xxl, AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.parcelsTrackGrey, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            _buildImage(),
            const SizedBox(width: AppSpacing.xl),
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre + precio
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.parcelsTextPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        product.price,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ],
                  ),
                  // Tipo + marca
                  if (typeStr != null) ...[
                    const SizedBox(height: AppSpacing.xxsPlus),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: AppSpacing.xsPlus, top: AppSpacing.hairline),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _typeColor,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            typeStr +
                                (product.brand != null
                                    ? ' · ${product.brand}'
                                    : ''),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.parcelsTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  // Barra de eficacia
                  Row(
                    children: [
                      Text(
                        'Eficacia estimada',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppColors.parcelsTextSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$effPct%',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xsPlus),
                    child: SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(
                        value: eff,
                        backgroundColor: AppColors.parcelsTrackGrey,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.forestGreen,
                        ),
                      ),
                    ),
                  ),
                  // Badge
                  if (badge != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        ProductBadgeChip(label: badge.label, color: badge.color),
                        const SizedBox(width: AppSpacing.smMd),
                        Expanded(
                          child: Text(
                            badge.desc,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: AppColors.parcelsTextSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Enlace
                  if (product.purchaseUrl != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => _launch(product.purchaseUrl!),
                        child: Text(
                          'Ver producto →',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    const sz = 64.0;
    final placeholder = Container(
      width: sz,
      height: sz,
      decoration: BoxDecoration(
        color: AppColors.diagnosisProductImageBg,
        borderRadius: BorderRadius.circular(AppRadius.mdLg),
      ),
      child: const Icon(
        Icons.eco_outlined,
        size: 28,
        color: AppColors.forestGreen,
      ),
    );

    if (product.imageUrl == null) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.mdLg),
      child: Image.network(
        product.imageUrl!,
        width: sz,
        height: sz,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : placeholder,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}
