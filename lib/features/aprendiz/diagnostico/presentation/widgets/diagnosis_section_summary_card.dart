import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'diagnosis_section_item.dart';

/// Tarjeta resumen de una sección del diagnóstico, mostrada dentro del
/// carrusel horizontal (`DiagnosisSectionCarousel`). Muestra solo lo
/// esencial — icono, título y una línea de resumen — para que el usuario
/// decida qué explorar antes de ver el contenido completo.
class DiagnosisSectionSummaryCard extends StatefulWidget {
  final DiagnosisSectionItem item;
  final int index;
  final VoidCallback onTap;

  const DiagnosisSectionSummaryCard({
    super.key,
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  State<DiagnosisSectionSummaryCard> createState() => _DiagnosisSectionSummaryCardState();
}

class _DiagnosisSectionSummaryCardState extends State<DiagnosisSectionSummaryCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + (widget.index * 90)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, (1 - value) * 24), child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xxlPlus),
            decoration: BoxDecoration(
              color: item.background,
              borderRadius: BorderRadius.circular(AppRadius.xhuge),
              border: Border.all(color: item.border),
              boxShadow: [
                BoxShadow(color: AppColors.aOnSurface.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'diagnosis-section-icon-${item.id}',
                  child: Material(
                    color: AppColors.transparent,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: item.accent.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(item.icon, color: item.accent, size: 24),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  item.title,
                  style: AppTypography.agendaSectionTitle.copyWith(color: AppColors.aOnSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.summary,
                  style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Toca para leer', style: AppTypography.etiquetaSm.copyWith(color: item.accent, fontWeight: FontWeight.w700)),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: item.accent),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
