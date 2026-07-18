import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../utils/card_detector.dart';

/// Campo de vista previa de tarjeta con deteccion de marca en tiempo real
/// (ver API.md > "Detector de tipo de tarjeta"). El pago real se completa en
/// la pagina segura de PayPal: este campo NUNCA se envia ni se persiste
/// (ver [SubscriptionRepository] / API.md), por lo que no requiere CVV ni
/// fecha de vencimiento.
class CardNumberField extends StatefulWidget {
  final ValueChanged<CardType>? onCardTypeChanged;

  const CardNumberField({super.key, this.onCardTypeChanged});

  @override
  State<CardNumberField> createState() => _CardNumberFieldState();
}

class _CardNumberFieldState extends State<CardNumberField> {
  final _controller = TextEditingController();
  CardType _type = CardType.unknown;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final type = CardDetector.detect(value);
    if (type != _type) setState(() => _type = type);
    widget.onCardTypeChanged?.call(type);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(CardDetector.maxDigits(_type)),
          ],
          onChanged: _onChanged,
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            labelText: 'Número de tarjeta (vista previa)',
            hintText: '1234 5678 9012 3456',
            prefixIcon: const Icon(Icons.credit_card_rounded, color: AppColors.onSurfaceVariant),
            suffixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
              child: _type == CardType.unknown
                  ? const SizedBox.shrink(key: ValueKey('empty'))
                  : Padding(
                      key: ValueKey(_type),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: _CardBrandBadge(type: _type),
                    ),
            ),
            filled: true,
            fillColor: AppColors.cardSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lgXl),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lgXl),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lgXl),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Este dato no se guarda ni se envía. Completarás tu pago de forma segura en PayPal.',
                style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CardBrandBadge extends StatelessWidget {
  final CardType type;
  const _CardBrandBadge({required this.type});

  Color get _brandColor => switch (type) {
        CardType.visa => AppColors.infoBlue,
        CardType.mastercard => AppColors.burntOrange,
        CardType.amex => AppColors.primary,
        CardType.discover => AppColors.warmAmber,
        CardType.unknown => AppColors.onSurfaceVariant,
      };

  @override
  Widget build(BuildContext context) {
    final color = _brandColor;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.credit_card_rounded, size: 14, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            CardDetector.label(type),
            style: AppTypography.etiquetaSm.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
