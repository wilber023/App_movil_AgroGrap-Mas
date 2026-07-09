import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../bloc/cultivo_bloc.dart';

/// Boton inferior del formulario de registro. Muestra un spinner mientras
/// `CultivoBloc` esta procesando el registro (`CultivoRegistering`).
class CultivoRegisterSubmitButton extends StatelessWidget {
  final bool canSubmit;
  final VoidCallback onPressed;

  const CultivoRegisterSubmitButton({
    super.key,
    required this.canSubmit,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CultivoBloc, CultivoState>(
      builder: (context, state) {
        final isRegistering = state is CultivoRegistering;
        final isEnabled = canSubmit && !isRegistering;
        return ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.aSecondary,
            disabledBackgroundColor: AppColors.aSurfaceVariant,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: isRegistering
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.aOnPrimary),
                )
              : Text(
                  canSubmit ? '🌱  Crear mi cultivo' : 'Completa los 3 pasos',
                  style: AppTypography.labelMd.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: canSubmit ? AppColors.aOnPrimary : AppColors.aOnSurfaceVariant,
                  ),
                ),
        );
      },
    );
  }
}
