import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import 'diagnosis_section_detail_sheet.dart';
import 'diagnosis_section_item.dart';
import 'diagnosis_section_summary_card.dart';

/// Carrusel horizontal de secciones del diagnóstico: cada tarjeta ocupa
/// ~84% del ancho disponible, deja ver parcialmente la siguiente para
/// invitar a deslizar, y muestra un indicador de páginas. Al tocar una
/// tarjeta se abre su experiencia inmersiva (`showDiagnosisSectionDetail`).
class DiagnosisSectionCarousel extends StatefulWidget {
  final List<DiagnosisSectionItem> items;
  const DiagnosisSectionCarousel({super.key, required this.items});

  @override
  State<DiagnosisSectionCarousel> createState() => _DiagnosisSectionCarouselState();
}

class _DiagnosisSectionCarouselState extends State<DiagnosisSectionCarousel> {
  late final PageController _controller = PageController(viewportFraction: 0.84);
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final page = _controller.page;
    if (page == null) return;
    setState(() => _page = page);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final delta = (_page - index).clamp(-1.0, 1.0).abs();
              final scale = 1 - (delta * 0.06);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: 1 - (delta * 0.3),
                    child: DiagnosisSectionSummaryCard(
                      item: item,
                      index: index,
                      onTap: () => showDiagnosisSectionDetail(context, item),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    height: 6,
                    width: _page.round() == i ? 22 : 6,
                    decoration: BoxDecoration(
                      color: _page.round() == i ? items[i].accent : AppColors.aOutlineVariant,
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
