import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Botón "Analizar foto" de [DiagnosisEntryAprendizPage], con estado de
/// carga y estado deshabilitado (sin foto aún).
class DiagnosisAnalyzeSubmitButton extends StatelessWidget {
  const DiagnosisAnalyzeSubmitButton({
    super.key,
    required this.hasPhoto,
    required this.isAnalyzing,
    required this.onPressed,
  });

  final bool hasPhoto;
  final bool isAnalyzing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (hasPhoto && !isAnalyzing) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.aOrange,
          disabledBackgroundColor: AppColors.aSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
          elevation: 0,
        ),
        child: isAnalyzing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: AppColors.aOnPrimary, strokeWidth: 2),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Text(
                    'Analizando tu foto...',
                    style: AppTypography.labelMd.copyWith(color: AppColors.aOnPrimary, fontSize: 15),
                  ),
                ],
              )
            : Text(
                hasPhoto ? 'Analizar foto' : 'Primero agrega una foto',
                style: AppTypography.labelMd.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: hasPhoto ? AppColors.aOnPrimary : AppColors.aOnSurfaceVariant,
                  letterSpacing: 0.1,
                ),
              ),
      ),
    );
  }
}
