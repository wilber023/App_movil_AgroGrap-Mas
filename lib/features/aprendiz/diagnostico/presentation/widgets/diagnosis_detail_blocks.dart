import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Bloques de contenido reutilizables dentro de la vista expandida de una
/// sección del diagnóstico (`DiagnosisSectionDetailSheet`). Mantienen
/// tipografía cómoda, buen contraste y espaciado amplio para lectura de
/// usuarios principiantes.

/// Párrafo de lectura cómoda (line-height amplio, tamaño de cuerpo).
class DiagnosisDetailParagraph extends StatelessWidget {
  final String text;
  const DiagnosisDetailParagraph(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyMd.copyWith(color: AppColors.aOnSurfaceVariant, height: 1.6),
    );
  }
}

/// Etiqueta pequeña en mayúsculas para introducir un subgrupo de contenido.
class DiagnosisDetailSectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const DiagnosisDetailSectionLabel(this.text, {super.key, this.color = AppColors.aOnSurface});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Text(
        text,
        style: AppTypography.etiquetaBold.copyWith(color: color, letterSpacing: 0.2),
      ),
    );
  }
}

/// Lista de pasos numerados, cada uno con espacio generoso — evita bloques
/// densos de texto al dividir el contenido en unidades pequeñas y claras.
class DiagnosisDetailStepList extends StatelessWidget {
  final List<String> items;
  final Color accent;
  const DiagnosisDetailStepList({super.key, required this.items, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : AppSpacing.xl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Text('${i + 1}', style: AppTypography.etiquetaBold.copyWith(color: accent)),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      items[i],
                      style: AppTypography.bodyMd.copyWith(color: AppColors.aOnSurface, height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Bloque destacado (dato curioso, advertencia) con fondo e icono propios.
class DiagnosisDetailCallout extends StatelessWidget {
  final String text;
  final Color background;
  final Color border;
  final Color textColor;
  final IconData icon;

  const DiagnosisDetailCallout({
    super.key,
    required this.text,
    required this.background,
    required this.border,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: Text(text, style: AppTypography.bodyMd.copyWith(color: textColor, height: 1.5))),
        ],
      ),
    );
  }
}
