import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../bloc/diagnosis_bloc.dart';
import 'diagnosis_processing_page.dart';
import 'diagnosis_history_page.dart';
import '../widgets/diagnosis_captured_panel.dart';
import '../widgets/diagnosis_focus_frame.dart';
import '../widgets/diagnosis_idle_placeholder.dart';
import '../widgets/diagnosis_shooting_bar.dart';
import '../widgets/diagnosis_top_bar.dart';
import '../widgets/diagnosis_vignette_overlay.dart';

// =============================================================================
// AgroGraph-MAS -- Diagnóstico con cámara nativa
// =============================================================================

// Top-level: corre en isolate separado para no bloquear la UI
Future<String> _compressToJpeg(String sourcePath) async {
  try {
    final rawBytes = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) return sourcePath;
    final output = decoded.width > 1280
        ? img.copyResize(decoded, width: 1280)
        : decoded;
    final jpegBytes = img.encodeJpg(output, quality: 82);
    await File(sourcePath).writeAsBytes(jpegBytes);
    return sourcePath;
  } catch (_) {
    return sourcePath;
  }
}

class DiagnosisPage extends StatefulWidget {
  final String? parcelId;
  final String? parcelName;
  const DiagnosisPage({super.key, this.parcelId, this.parcelName});

  @override
  State<DiagnosisPage> createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<DiagnosisPage>
    with TickerProviderStateMixin {
  // ── Estado ────────────────────────────────────────────────────────────────
  bool _isCapturing = false;

  // ── Animaciones ────────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── Texto adicional del usuario ────────────────────────────────────────────
  final TextEditingController _symptomsController = TextEditingController();
  String? _symptomsError;

  // ── Guía cíclica ───────────────────────────────────────────────────────────
  static const List<String> _guideMessages = [
    'Centra bien la hoja o fruto',
    'Evita sombras fuertes',
    'Acércate un poco más al cultivo',
    'La imagen clara mejora el diagnóstico',
  ];
  int _guideIndex = 0;
  Timer? _guideTimer;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startGuideTimer();
    _symptomsController.addListener(_onSymptomsChanged);
  }

  @override
  void dispose() {
    _guideTimer?.cancel();
    _pulseController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  // ── Validación de síntomas ────────────────────────────────────────────────

  void _onSymptomsChanged() {
    if (_symptomsError != null) setState(() => _symptomsError = null);
  }

  /// Devuelve un mensaje de error si el texto no cumple la calidad mínima,
  /// o null si es válido (incluido el caso de estar vacío).
  String? _validateSymptomsText(String raw) {
    if (raw.trim().isEmpty) return null; // campo opcional — vacío es válido

    final normalized = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    final noSpaces = normalized.replaceAll(' ', '');

    // Mínimo 10 caracteres significativos (sin espacios)
    if (noSpaces.length < 10) {
      return 'Si agregas una descripción, escribe al menos 10 caracteres '
          'sobre el problema observado.';
    }

    // Debe contener al menos una letra
    if (!RegExp(r'[a-záéíóúüñA-ZÁÉÍÓÚÜÑ]').hasMatch(normalized)) {
      return 'La descripción debe contener palabras, no solo números o símbolos.';
    }

    // Al menos una palabra con ≥ 3 letras y más de un carácter único
    final words = normalized.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final hasMeaningful = words.any((w) {
      final letters = w
          .replaceAll(RegExp(r'[^a-záéíóúüñA-ZÁÉÍÓÚÜÑ]'), '')
          .toLowerCase();
      return letters.length >= 3 && letters.split('').toSet().length > 1;
    });

    if (!hasMeaningful) {
      return 'Describe el problema con palabras claras,\n'
          'ej: "manchas amarillas en las hojas".';
    }

    return null;
  }

  // ── Captura ───────────────────────────────────────────────────────────────

  Future<void> _captureWithNativeCamera() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      // null → el usuario canceló: no lanzar error
      if (image == null || !mounted) return;
      final compressedPath = await compute(_compressToJpeg, image.path);
      if (mounted) {
        _guideTimer?.cancel();
        _pulseController.stop();
        context.read<DiagnosisBloc>().add(
          DiagnosisPhotoCaptured(compressedPath),
        );
      }
    } catch (e) {
      debugPrint('[DiagnosisPage] Error cámara nativa: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isCapturing) return;
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
      );
      if (image != null && mounted) {
        _guideTimer?.cancel();
        _pulseController.stop();
        context.read<DiagnosisBloc>().add(DiagnosisPhotoCaptured(image.path));
      }
    } catch (e) {
      debugPrint('[DiagnosisPage] Error galería: $e');
    }
  }

  Future<void> _retakePhoto() async {
    _symptomsController.clear();
    if (_symptomsError != null) setState(() => _symptomsError = null);
    context.read<DiagnosisBloc>().add(const DiagnosisCameraIdle());
    if (mounted) {
      _pulseController.repeat(reverse: true);
      _startGuideTimer();
    }
  }

  void _processWithAI() {
    final error = _validateSymptomsText(_symptomsController.text);
    if (error != null) {
      setState(() => _symptomsError = error);
      return;
    }

    final text = _symptomsController.text.trim();
    context.read<DiagnosisBloc>().add(
      DiagnosisProcessRequested(
        userText: text.isEmpty ? null : text,
        parcelId: widget.parcelId,
        parcelName: widget.parcelName,
      ),
    );
    _symptomsController.clear();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DiagnosisProcessingPage()),
    );
  }

  void _startGuideTimer() {
    _guideTimer?.cancel();
    _guideTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) {
        setState(() {
          _guideIndex = (_guideIndex + 1) % _guideMessages.length;
        });
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DiagnosisBloc, DiagnosisState>(
      listener: (context, state) {
        if (state is DiagnosisIdle ||
            state is DiagnosisResult ||
            state is DiagnosisError) {
          if (!_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          }
          if (_guideTimer == null || !_guideTimer!.isActive) {
            _startGuideTimer();
          }
        }
      },
      builder: (context, state) {
        final isCaptured = state is DiagnosisCaptured;

        final String? capturedPath = state is DiagnosisCaptured
            ? state.imagePath
            : state is DiagnosisProcessing
            ? state.imagePath
            : null;

        return Scaffold(
          backgroundColor: AppColors.black,
          body: Stack(
            children: [
              // ── Fondo ──────────────────────────────────────────────────
              if (capturedPath != null)
                Positioned.fill(
                  child: Image.file(File(capturedPath), fit: BoxFit.cover),
                )
              else
                const Positioned.fill(child: DiagnosisIdlePlaceholder()),

              // Overlay oscuro sobre imagen capturada
              if (isCaptured)
                Positioned.fill(
                  child: Container(color: AppColors.black.withValues(alpha: 0.38)),
                ),

              if (!isCaptured) const DiagnosisVignetteOverlay(),
              DiagnosisTopBar(isCaptured: isCaptured, onRetake: _retakePhoto),
              DiagnosisFocusFrame(
                isCaptured: isCaptured,
                pulseAnimation: _pulseAnimation,
                guideMessage: _guideMessages[_guideIndex],
                guideMessageKey: _guideIndex,
              ),
              Positioned(
                bottom: AppSpacing.none,
                left: AppSpacing.none,
                right: AppSpacing.none,
                child: isCaptured
                    ? DiagnosisCapturedPanel(
                        symptomsController: _symptomsController,
                        symptomsError: _symptomsError,
                        onRetake: _retakePhoto,
                        onAnalyze: _processWithAI,
                        onGallery: _pickFromGallery,
                      )
                    : DiagnosisShootingBar(
                        isCapturing: _isCapturing,
                        onHistory: _openHistory,
                        onShutter: _captureWithNativeCamera,
                        onGallery: _pickFromGallery,
                      ),
              ),

              // Indicador mientras se abre la cámara / galería
              if (_isCapturing)
                Positioned.fill(
                  child: Container(
                    color: AppColors.black.withValues(alpha: 0.45),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.onPrimary),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (ctx, scrollController) {
          return DiagnosisHistorySheet(scrollController: scrollController);
        },
      ),
    );
  }
}
