// =============================================================================
// Feature: Auth -- Widget: Campo de Texto Premium
// =============================================================================
// Diseño orgánico: sin bordes visibles, fondo #F4F8F6, sombra suave difuminada.
// La sombra se anima de neutra (gris-verdosa) a cálida-verde en foco.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
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

  // ── Paleta de tokens del campo ─────────────────────────────────────────────
  // Fondo del contenedor: verde salvia extremadamente apagado
  static const Color _fieldBg   = Color(0xFFF4F8F6);
  // Gris piedra atenuado para iconos outline
  static const Color _iconColor = Color(0xFF9BA89E);
  // Placeholder muy suave
  static const Color _hintColor = Color(0xFFAAB9B3);
  // Texto del usuario: verde bosque profundo (no negro puro)
  static const Color _textColor = Color(0xFF2A3D35);
  // Etiqueta: verde musgo medio — jerárquicamente menor que el texto principal
  static const Color _labelColor = Color(0xFF56706A);
  // Verde foco — indica actividad sin agresividad
  static const Color _focusGreen = Color(0xFF4A7C59);

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
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              widget.label,
              style: AppTypography.etiquetaBold.copyWith(
                color: _labelColor,
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
            color: _fieldBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isFocused
                ? [
                    // Sombra expandida verde cuando está en foco
                    BoxShadow(
                      color: _focusGreen.withValues(alpha: 0.14),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: const Offset(0, 6),
                    ),
                    // Capa inferior difuminada más sutil
                    BoxShadow(
                      color: _focusGreen.withValues(alpha: 0.06),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    // Sombra neutra en reposo — muy suave, flotación mínima
                    BoxShadow(
                      color: const Color(0xFF2A3D35).withValues(alpha: 0.06),
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
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            validator: widget.validator,
            onChanged: widget.onChanged,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            style: AppTypography.bodyMd.copyWith(
              color: _textColor,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTypography.bodyMd.copyWith(
                color: _hintColor,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: _iconColor, size: 20)
                  : null,
              suffixIcon: widget.suffixIcon,
              // El Container ya provee el fondo: fill transparente
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              // Sin líneas visibles — el volumen lo dan las sombras
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              // Error: borde terracota sutil — única situación con línea
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.75),
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
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
