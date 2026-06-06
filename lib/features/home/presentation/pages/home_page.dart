import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../diagnosis/presentation/pages/diagnosis_page.dart';
import '../../../subscription/presentation/pages/subscription_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo verde menta palido (si background no es suficientemente claro, usamos un color fijo suave)
      backgroundColor: const Color(0xFFF2F8F4),
      body: SafeArea(
        child: Column(
          children: [
            // 1. BANNER SUPERIOR DE ESTADO (Offline)
            _buildOfflineBanner(),

            // 2. ENCABEZADO PRINCIPAL
            _buildHeader(),

            // CUERPO DESLIZABLE
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 2.5 BANNER PREMIUM DISCRETO
                    _buildPremiumBanner(context),
                    const SizedBox(height: 24),

                    // 3. TARJETA ACCION DE CAMARA
                    _buildCameraActionCard(context),
                    const SizedBox(height: 24),

                    // 4. TARJETA DE ALERTA SANITARIA
                    _buildRegionalAlertCard(),
                    const SizedBox(height: 16),

                    // 5. TARJETA DE RECORDATORIO
                    _buildReminderCard(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Banner superior gris oscuro para estado Offline
  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF4A4A4A), // Gris oscuro / marron
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            'Sin conexion \u00B7 2 elementos en cola',
            style: AppTypography.etiquetaSm.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Encabezado principal simulando el AppBar
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: AppColors.forestGreen, // Verde oscuro
      child: Row(
        children: [
          // Izquierda: Saludo
          Text(
            'Hola, Wil 👋',
            style: AppTypography.tituloMd.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),

          // Centro: Etiqueta PLAN FREE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.statusHealthyBg, // Verde claro
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'PLAN FREE',
              style: AppTypography.etiquetaSm.copyWith(
                color: AppColors.forestGreen,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),

          // Derecha: Icono de campana
          const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 26,
          ),
        ],
      ),
    );
  }

  /// 2.5 Banner Premium Discreto (Sutil)
  Widget _buildPremiumBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.4), // Verde menta muy suave
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryContainer.withValues(alpha: 0.8),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.stars_rounded,
              color: AppColors.warmAmber,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'Obten diagnosticos ilimitados y alertas avanzadas. '),
                    TextSpan(
                      text: 'Mejorar a Pro \u2192',
                      style: AppTypography.etiquetaSm.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Gran banner verde para la accion de camara
  Widget _buildCameraActionCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DiagnosisPage()),
        );
      },
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Boton circular blanco translucido
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const Spacer(),
            // Titulo principal
            Text(
              'Tomar foto del cultivo',
              style: AppTypography.tituloLg.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Subtitulo tenue
            Text(
              'Diagnostico en segundos \u00B7 funciona sin senal',
              style: AppTypography.bodyMd.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4. Tarjeta de alerta sanitaria regional
  Widget _buildRegionalAlertCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), // Crema/Naranja muy claro
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.burntOrange.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de la alerta
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.burntOrange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'ALERTA REGIONAL',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.burntOrange,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Titulo principal
          Text(
            'Tizon tardio',
            style: AppTypography.tituloLg.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Subtitulo descriptivo
          Text(
            '3 km \u00B7 4 casos confirmados en tu zona',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Tarjeta de recordatorio (Segunda aplicacion)
  Widget _buildReminderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: Icono, titulo y etiqueta
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SEGUNDA APLICACION',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh, // Gris claro
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'MANANA',
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Titulo principal
          Text(
            'Gusano cogollero',
            style: AppTypography.tituloMd.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Subtitulo
          Text(
            'Lote Norte \u00B7 Revisar efectividad',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
