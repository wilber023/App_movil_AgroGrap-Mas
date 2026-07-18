import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Piezas de formulario reutilizadas por [AddParcelPage]: tarjeta contenedora,
/// etiqueta de campo, input de texto, selector de unidad, selector de fecha
/// y pastilla de etapa fenológica estimada. Puramente de presentación — sin
/// lógica de negocio ni validación (eso vive en el estado de la página).

class ParcelFormCard extends StatelessWidget {
  const ParcelFormCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.parcelsBorderLight.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: child,
    );
  }
}

class ParcelFieldLabel extends StatelessWidget {
  const ParcelFieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.parcelsTextSecondary,
      ),
    );
  }
}

class ParcelOptionalHeader extends StatelessWidget {
  const ParcelOptionalHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.parcelsTextPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.parcelsBorderLight),
        ),
      ],
    );
  }
}

class ParcelTextInput extends StatelessWidget {
  const ParcelTextInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: AppColors.parcelsTextPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppColors.parcelsBorderLight, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.parcelsTextSecondary, size: 16),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xxl,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.mdLg),
            borderSide: BorderSide(
              color: AppColors.parcelsBorderLight.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.mdLg),
            borderSide: BorderSide(
              color: AppColors.parcelsBorderLight.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.mdLg),
            borderSide: const BorderSide(color: AppColors.forestGreen, width: 1),
          ),
        ),
      ),
    );
  }
}

class ParcelUnitDropdown extends StatelessWidget {
  const ParcelUnitDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const options = ['Hectáreas', 'm²'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.mdLg),
        border: Border.all(
          color: AppColors.parcelsBorderLight.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: GoogleFonts.inter(color: AppColors.parcelsTextPrimary, fontSize: 13),
          items: options
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class ParcelDatePickerField extends StatelessWidget {
  const ParcelDatePickerField({
    super.key,
    required this.selectedDate,
    required this.onTap,
  });

  final DateTime? selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.mdLg),
          border: Border.all(
            color: AppColors.parcelsBorderLight.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.parcelsTextSecondary,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(
              selectedDate != null
                  ? '${selectedDate!.day.toString().padLeft(2, '0')} / '
                        '${selectedDate!.month.toString().padLeft(2, '0')} / '
                        '${selectedDate!.year}'
                  : 'DD / MM / AAAA',
              style: GoogleFonts.inter(
                color: selectedDate != null ? AppColors.parcelsTextPrimary : AppColors.parcelsBorderLight,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParcelStagePill extends StatelessWidget {
  const ParcelStagePill(this.stage, {super.key});
  final String stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.parcelsChipGreenBg,
        borderRadius: BorderRadius.circular(AppRadius.mdLg),
      ),
      child: Text(
        'Etapa estimada: $stage',
        style: GoogleFonts.inter(
          fontSize: 10,
          color: AppColors.parcelsChipGreenText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
