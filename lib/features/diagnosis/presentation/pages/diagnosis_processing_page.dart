import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/diagnosis_bloc.dart';
import 'diagnosis_result_page.dart';

// =============================================================================
// AgroGraph-MAS -- Procesando Diagnostico (pantalla de inferencia)
// =============================================================================
// Pantalla fullscreen mostrada durante el analisis de IA. Incluye foto circular,
// animacion de tres puntos, subtitulos ciclicos y contexto del cultivo.
// =============================================================================

class DiagnosisProcessingPage extends StatefulWidget {
  const DiagnosisProcessingPage({super.key});

  @override
  State<DiagnosisProcessingPage> createState() =>
      _DiagnosisProcessingPageState();
}

class _DiagnosisProcessingPageState extends State<DiagnosisProcessingPage>
    with TickerProviderStateMixin {
  late AnimationController _dotController;
  int _subtitleIndex = 0;
  Timer? _subtitleTimer;

  static const List<String> _subtitles = [
    'Ejecutando modelo CNN EfficientNetB4...',
    'Procesando localmente \u00B7 sin necesidad de internet...',
    'Comparando con 40+ patologias conocidas...',
    'Calculando nivel de confianza...',
  ];

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Cycle subtitles every 1.5 seconds
    _subtitleTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (mounted) {
        setState(() {
          _subtitleIndex = (_subtitleIndex + 1) % _subtitles.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _dotController.dispose();
    _subtitleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DiagnosisBloc, DiagnosisState>(
      listener: (context, state) {
        if (state is DiagnosisResult) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DiagnosisResultPage(diagnosis: state.diagnosis),
            ),
          );
        } else if (state is DiagnosisError) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFA32D2D),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        String displayCrop = '';
        String? capturedImagePath;
        if (state is DiagnosisProcessing) {
          displayCrop = state.parcelName != null
              ? '${state.cropName} \u00B7 ${state.parcelName}'
              : state.cropName;
          capturedImagePath = state.imagePath;
        }

        return Scaffold(
          backgroundColor: AppColors.forestGreen,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Foto capturada en c\u00EDrculo
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: ClipOval(
                            child: capturedImagePath != null &&
                                    File(capturedImagePath).existsSync()
                                ? Image.file(
                                    File(capturedImagePath),
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                  )
                                : const Icon(
                                    Icons.eco_outlined,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Wave dots animation
                        _buildWaveDots(),
                        const SizedBox(height: 16),
                        // Title
                        Text(
                          'Analizando imagen...',
                          style: AppTypography.labelMd.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Cycling subtitle
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _subtitles[_subtitleIndex],
                            key: ValueKey(_subtitleIndex),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Crop context
                        if (displayCrop.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.eco_outlined,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  displayCrop,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Cancel button at bottom
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      context.read<DiagnosisBloc>().add(const DiagnosisCameraIdle());
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancelar analisis',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveDots() {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final offset = i * 0.33;
            final t = (_dotController.value + offset) % 1.0;
            final scale = 0.6 + 0.4 * (1.0 - (2 * t - 1.0).abs());
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10 * scale,
              height: 10 * scale,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
