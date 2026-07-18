// =============================================================================
// Feature: Auth -- Widget: Campo de Texto Premium
// =============================================================================
// Diseño orgánico: sin bordes visibles, fondo #F4F8F6, sombra suave difuminada.
// La sombra se anima de neutra (gris-verdosa) a cálida-verde en foco.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final int maxLines;

  const AuthTextField({
    super.key,
    this.controller,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late final FocusNode _focus;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() => _isFocused = _focus.hasFocus);

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etiqueta exterior — fuera del contenedor, texto limpio
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.lg,
            ),
            child: Text(
              widget.label,
              style: AppTypography.etiquetaBold.copyWith(
                color: AppColors.authFieldLabel,
                fontSize: 11,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        // Contenedor del campo — proporciona fondo y sombra animada
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: AppColors.authFieldBg,
            borderRadius: BorderRadius.circular(AppRadius.xlPlus),
            boxShadow: _isFocused
                ? [
                    // Sombra expandida verde cuando está en foco
                    BoxShadow(
                      color: AppColors.authFieldFocusGreen.withValues(alpha: 0.14),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: const Offset(0, 6),
                    ),
                    // Capa inferior difuminada más sutil
                    BoxShadow(
                      color: AppColors.authFieldFocusGreen.withValues(alpha: 0.06),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    // Sombra neutra en reposo — muy suave, flotación mínima
                    BoxShadow(
                      color: AppColors.authFieldText.withValues(alpha: 0.06),
                      blurRadius: 14,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: TextFormField(
            focusNode: _focus,
            controller: widget.controller,
            obscureText: widget.obscureText,
            // MASVS-PLATFORM (UI segura): en campos de contraseña se
            // deshabilita el autocompletado/corrector y el cache de teclado
            // para que el SO no sugiera ni recuerde la contraseña en texto
            // plano.
            enableSuggestions: widget.obscureText ? false : true,
            autocorrect: widget.obscureText ? false : true,
            keyboardType: widget.obscureText ? TextInputType.visiblePassword : widget.keyboardType,
            textInputAction: widget.textInputAction,
            validator: widget.validator,
            onChanged: widget.onChanged,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.authFieldText,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTypography.bodyMd.copyWith(
                color: AppColors.authFieldHint,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: AppColors.authFieldIcon, size: 20)
                  : null,
              suffixIcon: widget.suffixIcon,
              // El Container ya provee el fondo: fill transparente
              filled: true,
              fillColor: AppColors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxlPlus,
                vertical: AppSpacing.xxlPlus,
              ),
              // Sin líneas visibles — el volumen lo dan las sombras
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xlPlus),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xlPlus),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xlPlus),
                borderSide: BorderSide.none,
              ),
              // Error: borde terracota sutil — única situación con línea
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xlPlus),
                borderSide: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.75),
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xlPlus),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
