import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show compute;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../bloc/diagnosis_bloc.dart';
import 'diagnosis_processing_page.dart';
import 'diagnosis_history_page.dart';

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
                Positioned.fill(child: _buildIdlePlaceholder()),

              // Overlay oscuro sobre imagen capturada
              if (isCaptured)
                Positioned.fill(
                  child: Container(color: AppColors.black.withValues(alpha: 0.38)),
                ),

              if (!isCaptured) _buildVignette(),
              _buildTopBar(isCaptured),
              _buildFocusFrame(isCaptured),
              _buildBottomBar(isCaptured),

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

  // Fondo de espera antes de tomar foto
  Widget _buildIdlePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.diagnosisCameraGradientStart, AppColors.black],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 52,
              color: AppColors.onPrimary.withValues(alpha: 0.18),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Toca el botón para fotografiar\ntu cultivo',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onPrimary.withValues(alpha: 0.28),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(bool isCaptured) {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: AppSpacing.none,
      right: AppSpacing.none,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus),
        color: AppColors.black.withValues(alpha: 0.55),
        child: Row(
          children: [
            // Botón "Repetir" solo cuando hay foto capturada
            if (isCaptured)
              GestureDetector(
                onTap: _retakePhoto,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.onPrimary,
                    size: 18,
                  ),
                ),
              )
            else
              const SizedBox(width: AppSpacing.giantPlus),
            Expanded(
              child: Center(
                child: Text(
                  'Diagnóstico CNN',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
            // Espacio de balance
            const SizedBox(width: AppSpacing.giantPlus),
          ],
        ),
      ),
    );
  }

  Widget _buildVignette() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.85,
              colors: [
                AppColors.transparent,
                AppColors.black.withValues(alpha: 0.45),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusFrame(bool isCaptured) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final fw = sw * 0.75;
    final fh = sh * 0.50;

    return Positioned.fill(
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, _) {
            final scale = isCaptured ? 1.0 : _pulseAnimation.value;
            final bracketColor = isCaptured
                ? AppColors.warmAmber
                : AppColors.parcelsAddGreen;
            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: fw,
                height: fh,
                child: CustomPaint(
                  painter: _CornerBracketPainter(
                    color: bracketColor.withValues(
                      alpha: isCaptured ? 1.0 : _pulseAnimation.value,
                    ),
                    armLength: 26,
                    strokeWidth: 3,
                  ),
                  child: !isCaptured
                      ? Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: Text(
                              _guideMessages[_guideIndex],
                              key: ValueKey(_guideIndex),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.onPrimary.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isCaptured) {
    return Positioned(
      bottom: AppSpacing.none,
      left: AppSpacing.none,
      right: AppSpacing.none,
      child: isCaptured ? _buildCapturedPanel() : _buildShootingBar(),
    );
  }

  // Panel tras capturar: campo de síntomas + botones de acción
  Widget _buildCapturedPanel() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xxlPlus, AppSpacing.xxl, AppSpacing.xxlPlus, bottomPad + AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.82),
        border: Border(
          top: BorderSide(
            color: AppColors.onPrimary.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Etiqueta del campo ──────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 11,
                color: AppColors.onPrimary.withValues(alpha: 0.65),
              ),
              const SizedBox(width: AppSpacing.xsPlus),
              Text(
                'SÍNTOMAS OBSERVADOS  ·  OPCIONAL',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: AppColors.onPrimary.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // ── Campo de texto ──────────────────────────────────────────────
          TextField(
            controller: _symptomsController,
            maxLines: 2,
            maxLength: 400,
            style: GoogleFonts.inter(
              color: AppColors.onPrimary,
              fontSize: 12.5,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText:
                  'Ej: manchas amarillas en hojas, tallos negros, frutos caídos...',
              hintStyle: GoogleFonts.inter(
                color: AppColors.onPrimary.withValues(alpha: 0.50),
                fontSize: 11.5,
              ),
              errorText: _symptomsError,
              errorStyle: GoogleFonts.inter(
                color: AppColors.errorBright,
                fontSize: 10.5,
                height: 1.4,
              ),
              errorMaxLines: 3,
              filled: true,
              fillColor: AppColors.onPrimary.withValues(alpha: 0.13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mdLg),
                borderSide: BorderSide(
                  color: AppColors.onPrimary.withValues(alpha: 0.28),
                  width: 0.8,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mdLg),
                borderSide: BorderSide(
                  color: AppColors.onPrimary.withValues(alpha: 0.28),
                  width: 0.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mdLg),
                borderSide: const BorderSide(color: AppColors.parcelsAddGreen, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mdLg),
                borderSide: const BorderSide(
                  color: AppColors.errorBright,
                  width: 1.0,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mdLg),
                borderSide: const BorderSide(
                  color: AppColors.errorBright,
                  width: 1.5,
                ),
              ),
              counterStyle: GoogleFonts.inter(
                color: AppColors.onPrimary.withValues(alpha: 0.30),
                fontSize: 9,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
            ),
          ),
          // ── Botones ─────────────────────────────────────────────────────
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIconButton(
                  icon: Icons.refresh_outlined,
                  label: 'Repetir',
                  onTap: _retakePhoto,
                ),
                _buildAnalyzeButton(),
                _buildIconButton(
                  icon: Icons.photo_outlined,
                  label: 'Galería',
                  onTap: _pickFromGallery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Barra de disparo: historial / cámara / galería
  Widget _buildShootingBar() {
    return Container(
      height: 100,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      color: AppColors.black.withValues(alpha: 0.6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildIconButton(
            icon: Icons.access_time_outlined,
            label: 'Historial',
            onTap: _openHistory,
          ),
          _buildShutterButton(),
          _buildIconButton(
            icon: Icons.photo_outlined,
            label: 'Galería',
            onTap: _pickFromGallery,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.onPrimary.withValues(alpha: isDisabled ? 0.3 : 0.7),
              size: 22,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.onPrimary.withValues(alpha: isDisabled ? 0.25 : 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: _isCapturing ? null : _captureWithNativeCamera,
      child: AnimatedOpacity(
        opacity: _isCapturing ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.onPrimary.withValues(alpha: 0.35),
              width: 3,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.xs),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return GestureDetector(
      onTap: _processWithAI,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warmAmber,
            ),
            child: const Icon(
              Icons.search_outlined,
              color: AppColors.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Analizar',
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.onPrimary),
          ),
        ],
      ),
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

// =============================================================================
// Corner bracket painter
// =============================================================================
class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double armLength;
  final double strokeWidth;

  const _CornerBracketPainter({
    required this.color,
    required this.armLength,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final a = armLength;

    canvas.drawLine(Offset(0, a), Offset.zero, paint);
    canvas.drawLine(Offset.zero, Offset(a, 0), paint);

    canvas.drawLine(Offset(w - a, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, a), paint);

    canvas.drawLine(Offset(0, h - a), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(a, h), paint);

    canvas.drawLine(Offset(w, h - a), Offset(w, h), paint);
    canvas.drawLine(Offset(w - a, h), Offset(w, h), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter old) => color != old.color;
}
