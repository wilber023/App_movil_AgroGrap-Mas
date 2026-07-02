import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/diagnosis_bloc.dart';
import 'diagnosis_processing_page.dart';
import 'diagnosis_history_page.dart';

// =============================================================================
// AgroGraph-MAS -- Cámara de Diagnóstico
// =============================================================================

const Color _bracketGreen = Color(0xFF52B788);

// Top-level: corre en isolate separado para no bloquear la UI
Future<String> _compressToJpeg(String sourcePath) async {
  try {
    final rawBytes = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) return sourcePath;
    final output =
        decoded.width > 1280 ? img.copyResize(decoded, width: 1280) : decoded;
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── Cámara ────────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _cameraError = false;       // Diferencia "cargando" de "falló"
  bool _isCapturing = false;
  bool _isReinitializing = false;
  int _flashState = 0; // 0=off 1=on 2=auto

  // ── Animaciones ────────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── Texto adicional del usuario ────────────────────────────────────────────
  final TextEditingController _symptomsController = TextEditingController();

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
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startGuideTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _guideTimer?.cancel();
    _cameraController?.dispose();
    _pulseController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final stale = _cameraController;
      _cameraController = null;
      if (mounted) setState(() => _isCameraReady = false);
      stale?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (!_isReinitializing) _initCamera();
    }
  }

  // ── Cámara ────────────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    if (!mounted) { return; }
    setState(() => _cameraError = false);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty || !mounted) { return; }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      final old = _cameraController;
      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
        _cameraError = false;
      });
      if (old != null) {
        try {
          await old.dispose();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[DiagnosisPage] Error cámara: $e');
      if (mounted) setState(() => _cameraError = true);
    }
  }

  Future<void> _reinitCamera() async {
    if (!mounted) return;
    final stale = _cameraController;
    setState(() {
      _cameraController = null;
      _isCameraReady = false;
    });
    try {
      await stale?.dispose();
    } catch (_) {}
    await _initCamera();
  }

  void _toggleFlash() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) { return; }
    try {
      final next = (_flashState + 1) % 3;
      switch (next) {
        case 0:
          await _cameraController!.setFlashMode(FlashMode.off);
        case 1:
          await _cameraController!.setFlashMode(FlashMode.torch);
        case 2:
          await _cameraController!.setFlashMode(FlashMode.auto);
      }
      setState(() => _flashState = next);
    } catch (e) {
      debugPrint('[DiagnosisPage] Error flash: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) { return; }
    if (_cameraController!.value.isTakingPicture || _isCapturing) { return; }

    setState(() => _isCapturing = true);
    try {
      final image = await _cameraController!.takePicture();
      final compressedPath = await compute(_compressToJpeg, image.path);
      if (mounted) {
        _guideTimer?.cancel();
        _pulseController.stop();
        context.read<DiagnosisBloc>().add(DiagnosisPhotoCaptured(compressedPath));
      }
    } catch (e) {
      debugPrint('[DiagnosisPage] Error captura: $e');
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
    if (_isReinitializing) return;
    _symptomsController.clear();
    setState(() => _isReinitializing = true);
    try {
      context.read<DiagnosisBloc>().add(const DiagnosisCameraIdle());
      await _reinitCamera();
      if (mounted) {
        _pulseController.repeat(reverse: true);
        _startGuideTimer();
      }
    } finally {
      if (mounted) setState(() => _isReinitializing = false);
    }
  }

  void _processWithAI() {
    final text = _symptomsController.text.trim();
    context.read<DiagnosisBloc>().add(
          DiagnosisProcessRequested(
            userText: text.isEmpty ? null : text,
            parcelId: widget.parcelId,
            parcelName: widget.parcelName,
          ),
        );
    // Limpia para el próximo diagnóstico; el texto ya fue capturado arriba
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
      // Listener: reacciona a cambios de estado para restablecer UI de cámara
      listener: (context, state) {
        if (state is DiagnosisIdle ||
            state is DiagnosisResult ||
            state is DiagnosisError) {
          // Reanuda animaciones al volver al modo cámara activo
          if (!_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          }
          if (_guideTimer == null || !_guideTimer!.isActive) {
            _startGuideTimer();
          }
        }
        // Reinicia cámara si fue liberada (ej. cambio de ciclo de vida)
        if (state is DiagnosisIdle && !_isCameraReady && !_isReinitializing) {
          _initCamera();
        }
      },
      builder: (context, state) {
        // SOLO DiagnosisCaptured activa el panel de captura.
        // DiagnosisResult/Processing ya navegan a otras rutas —
        // cuando el usuario regresa, la cámara debe estar lista.
        final isCaptured = state is DiagnosisCaptured;

        // Imagen a mostrar como fondo (solo cuando hay foto disponible)
        final String? capturedPath = state is DiagnosisCaptured
            ? state.imagePath
            : state is DiagnosisProcessing
                ? state.imagePath
                : null;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // ── Fondo ──────────────────────────────────────────────────
              if (capturedPath != null)
                Positioned.fill(
                  child: Image.file(File(capturedPath), fit: BoxFit.cover),
                )
              else if (_isCameraReady && _cameraController != null)
                Positioned.fill(child: CameraPreview(_cameraController!))
              else
                Positioned.fill(child: _buildCameraPlaceholder()),

              // Overlay oscuro sobre imagen capturada
              if (isCaptured)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.38),
                  ),
                ),

              if (!isCaptured) _buildVignette(),
              _buildTopBar(),
              _buildFocusFrame(isCaptured),
              _buildBottomBar(isCaptured),

              // Indicador de captura en progreso
              if (_isCapturing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child:
                          CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Placeholder mientras la cámara carga o si falla
  Widget _buildCameraPlaceholder() {
    if (_cameraError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.no_photography_outlined,
              color: Colors.white.withValues(alpha: 0.45),
              size: 44,
            ),
            const SizedBox(height: 14),
            Text(
              'No se pudo iniciar la cámara',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _initCamera,
              style: TextButton.styleFrom(
                foregroundColor: _bracketGreen,
              ),
              child: const Text(
                'Reintentar',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _bracketGreen),
          if (_isReinitializing) ...[
            const SizedBox(height: 16),
            Text(
              'Reiniciando cámara...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.black.withValues(alpha: 0.55),
        child: Row(
          children: [
            GestureDetector(
              onTap: _isReinitializing ? null : _retakePhoto,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: _isReinitializing
                    ? const Center(
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 1.5,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Diagnóstico CNN',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: _toggleFlash,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _flashState == 0
                      ? Icons.flash_off_outlined
                      : _flashState == 1
                          ? Icons.flash_on_outlined
                          : Icons.flash_auto_outlined,
                  color: _flashState == 1
                      ? AppColors.warmAmber
                      : Colors.white,
                  size: 18,
                ),
              ),
            ),
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
                Colors.transparent,
                Colors.black.withValues(alpha: 0.45),
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
            final bracketColor =
                isCaptured ? AppColors.warmAmber : _bracketGreen;
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
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.75),
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
      bottom: 0,
      left: 0,
      right: 0,
      child: isCaptured ? _buildCapturedPanel() : _buildShootingBar(),
    );
  }

  // Panel de captura: campo de síntomas más visible + botones
  Widget _buildCapturedPanel() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad + 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
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
                color: Colors.white.withValues(alpha: 0.65),
              ),
              const SizedBox(width: 5),
              Text(
                'SÍNTOMAS OBSERVADOS  ·  OPCIONAL',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Campo de texto ──────────────────────────────────────────────
          TextField(
            controller: _symptomsController,
            maxLines: 2,
            maxLength: 400,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontSize: 12.5,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText:
                  'Ej: manchas amarillas en hojas, tallos negros, frutos caídos...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.50),
                fontSize: 11.5,
                fontFamily: 'Inter',
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.28),
                  width: 0.8,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.28),
                  width: 0.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _bracketGreen, width: 1.5),
              ),
              counterStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.30),
                fontSize: 9,
                fontFamily: 'Inter',
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  onTap: _isReinitializing ? null : _retakePhoto,
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

  // Barra mientras apunta la cámara
  Widget _buildShootingBar() {
    return Container(
      height: 100,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      color: Colors.black.withValues(alpha: 0.6),
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
              color: Colors.white.withValues(alpha: isDisabled ? 0.3 : 0.7),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: Colors.white.withValues(alpha: isDisabled ? 0.25 : 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: _isCapturing ? null : _takePicture,
      child: AnimatedOpacity(
        opacity: _isCapturing ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 3,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
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
            child: const Icon(Icons.search_outlined,
                color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          const Text(
            'Analizar',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _openHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (ctx, scrollController) {
          return DiagnosisHistorySheet(
              scrollController: scrollController);
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
  bool shouldRepaint(covariant _CornerBracketPainter old) =>
      color != old.color;
}
