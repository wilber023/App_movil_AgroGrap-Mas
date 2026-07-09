import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../agricultor/diagnosis/domain/entities/llm_response_entity.dart';
import 'aprendiz_agenda_page.dart';

const String _kFont = 'Inter';

/// Muestra el tratamiento/prevención recomendados por el asistente IA (LLM),
/// en lenguaje sencillo para el aprendiz. Sin datos económicos ni de producto
/// fabricados: si el LLM aún no respondió, se informa en vez de inventar cifras.
class AprendizRecommendedActionPage extends StatelessWidget {
  final String diseaseName;
  final String cropName;
  final LlmResponseEntity? llmResponse;

  const AprendizRecommendedActionPage({
    super.key,
    required this.diseaseName,
    required this.cropName,
    this.llmResponse,
  });

  @override
  Widget build(BuildContext context) {
    final r = llmResponse;

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
                      'Qué hacer ahora',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _kFont,
                        color: Colors.white,
                        fontSize: 19,
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
                          style: const TextStyle(fontFamily: _kFont, fontSize: 14, color: AppColors.aOnSurfaceVariant),
                          children: [
                            const TextSpan(
                              text: 'Sobre: ',
                              style: TextStyle(fontFamily: _kFont, fontWeight: FontWeight.w700, color: AppColors.aOnSurface),
                            ),
                            TextSpan(text: '$diseaseName · $cropName'),
                          ],
                        ),
                      ),
                    ),

                    if (r == null)
                      _InfoCard(
                        icon: Icons.hourglass_empty_rounded,
                        title: 'Aún no hay una recomendación disponible',
                        body: 'Vuelve a la pantalla de resultado y espera a que '
                            'el asistente IA termine de generar la explicación '
                            'para ver aquí el tratamiento sugerido.',
                      )
                    else ...[
                      if (r.tratamiento.isNotEmpty)
                        _ActionCard(
                          icon: Icons.healing_outlined,
                          label: 'QUÉ HACER',
                          content: r.tratamiento,
                        ),
                      if (r.prevencion.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _ActionCard(
                          icon: Icons.shield_outlined,
                          label: 'CÓMO PREVENIRLO',
                          content: r.prevencion,
                        ),
                      ],
                      if (r.tratamiento.isEmpty && r.prevencion.isEmpty)
                        _InfoCard(
                          icon: Icons.info_outline,
                          title: 'Sin recomendación específica',
                          body: 'El asistente IA no encontró un tratamiento '
                              'específico para este caso. Consulta a tu instructor.',
                        ),
                    ],

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
                          style: TextStyle(fontFamily: _kFont, color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.aOrange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          'Volver al resultado',
                          style: TextStyle(fontFamily: _kFont, fontSize: 14, color: AppColors.aOnSurfaceVariant, fontWeight: FontWeight.w600),
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String content;

  const _ActionCard({required this.icon, required this.label, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.aOutlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppColors.aMint, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.aSecondary, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 12,
                  color: AppColors.aSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontFamily: _kFont, fontSize: 15, color: AppColors.aOnSurface, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.aOutlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.aOnSurfaceVariant, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontFamily: _kFont, fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.aOnSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(fontFamily: _kFont, fontSize: 13, color: AppColors.aOnSurfaceVariant, height: 1.4),
          ),
        ],
      ),
    );
  }
}
