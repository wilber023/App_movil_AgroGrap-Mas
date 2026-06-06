import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ParcelsPage extends StatelessWidget {
  const ParcelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F4), // Fondo claro original de la app
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text(
          'Mis Parcelas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.warmAmber,
              size: 28,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Barra de busqueda
            _buildSearchBar(),
            const SizedBox(height: 24),

            // 2. Tarjeta 1: Alerta (Roja)
            _buildParcelCard(
              title: 'Milpa Norte',
              borderColor: AppColors.error,
              pillBackground: AppColors.errorContainer.withValues(alpha: 0.4),
              pillTextColor: AppColors.error,
              pillIcon: Icons.warning_amber_rounded,
              pillText: 'ALERTA',
            ),
            const SizedBox(height: 16),

            // 3. Tarjeta 2: Seguimiento (Marron/Naranja)
            _buildParcelCard(
              title: 'Huerta Baja',
              borderColor: AppColors.burntOrange,
              pillBackground: AppColors.warmAmber.withValues(alpha: 0.2),
              pillTextColor: AppColors.burntOrange,
              pillIcon: Icons.visibility_outlined,
              pillText: 'SEGUIMIENTO',
            ),
            const SizedBox(height: 16),

            // 4. Tarjeta 3: Saludable (Verde oscuro)
            _buildParcelCard(
              title: 'Terreno Sur',
              borderColor: AppColors.forestGreen,
              pillBackground: AppColors.statusHealthyBg,
              pillTextColor: AppColors.forestGreen,
              pillIcon: Icons.check_circle_outline_rounded,
              pillText: 'SALUDABLE',
            ),
            const SizedBox(height: 24),

            // 5. Boton Agregar Nueva Parcela
            _buildAddParcelButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Construye la barra de busqueda estilizada superior.
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar parcela...',
          hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  /// Construye una tarjeta de parcela con su respectivo estado visual.
  Widget _buildParcelCard({
    required String title,
    required Color borderColor,
    required Color pillBackground,
    required Color pillTextColor,
    required IconData pillIcon,
    required String pillText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: borderColor, width: 6),
          top: const BorderSide(color: AppColors.outlineVariant, width: 0.5),
          right: const BorderSide(color: AppColors.outlineVariant, width: 0.5),
          bottom: const BorderSide(color: AppColors.outlineVariant, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titulo y etiqueta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.tituloMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: pillBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          pillIcon,
                          size: 14,
                          color: pillTextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          pillText,
                          style: AppTypography.etiquetaSm.copyWith(
                            color: pillTextColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Icono de opciones
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.onSurfaceVariant),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la tarjeta punteada/estilizada para agregar una nueva parcela.
  Widget _buildAddParcelButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.3), // Menta muy palido
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryContainer,
            width: 1.5,
            // Simulando un marco limpio en lugar de instalar librerias de dash
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              'Agregar nueva parcela',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
