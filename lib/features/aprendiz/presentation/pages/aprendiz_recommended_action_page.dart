import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'aprendiz_agenda_page.dart';

class AprendizRecommendedActionPage extends StatelessWidget {
  final String diseaseName;
  final String cropName;
  final int weekNumber;

  const AprendizRecommendedActionPage({
    super.key,
    this.diseaseName = 'Tizón tardío',
    this.cropName = 'Maíz',
    this.weekNumber = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aMint,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              height: 56,
              color: AppColors.aPrimaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Acción recomendada',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumb
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 16),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant),
                          children: [
                            const TextSpan(
                              text: 'Basado en: ',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.aOnSurface),
                            ),
                            TextSpan(text: '$diseaseName · $cropName · Semana $weekNumber · Milpa Norte'),
                          ],
                        ),
                      ),
                    ),

                    // Main action card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Left accent bar
                          Positioned(
                            left: 0, top: 0, bottom: 0,
                            child: Container(
                              width: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Priority badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.aDiseaseCardBg,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8, height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'PRIORIDAD ALTA',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.05,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                const Text(
                                  'Aplicar fungicida sistémico',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.aOnSurface,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, color: AppColors.aOrange, size: 18),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Hoy · en las próximas 48 horas',
                                      style: TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Economic card
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.aWarningBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.aWarningBorder),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.payments_outlined, color: Color(0xFFB45309)),
                              const SizedBox(width: 8),
                              const Text(
                                '¿Conviene económicamente?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFFFFE5A3)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Costo estimado:', style: TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant)),
                              const Text(
                                '~\$320 MXN',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.aOnSurface),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Pérdida potencial:', style: TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant)),
                              const Text(
                                '\$1,800 – \$2,400 MXN',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.error),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: AppColors.aOnPrimaryFixedVariant, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Tratamiento recomendado',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.aOnPrimaryFixedVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // CTA buttons
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const AprendizAgendaPage()),
                          );
                        },
                        icon: const Icon(Icons.event_available, color: Colors.white),
                        label: const Text(
                          'Agregar a mi agenda',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.aOrange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Rechazar recomendación',
                          style: TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
