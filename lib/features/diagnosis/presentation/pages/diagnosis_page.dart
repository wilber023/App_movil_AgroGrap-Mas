import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/diagnosis_bloc.dart';
import 'diagnosis_processing_page.dart';
import 'diagnosis_history_page.dart';

// =============================================================================
// AgroGraph-MAS -- Cámara de Diagnóstico
// Captura imagen → CNN detecta cultivo + enfermedad + confianza (offline)
// =============================================================================

const Color _bracketGreen = Color(0xFF52B788);

class DiagnosisPage extends StatefulWidget {
  const DiagnosisPage({super.key});

  @override
  State<DiagnosisPage> createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<DiagnosisPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── Cámara ────────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _isCameraReady = false;
  int _flashState = 0; // 0=off 1=on 2=auto

  // ── Selección de cultivo (contexto opcional, CNN detecta automáticamente) ──
  int _selectedCropIndex = 0;

  static const List<String> _cropLabels = [
    'Calabaza', 'Frijol', 'Manzana', 'Mora', 'Cereza',
    'Maíz', 'Durazno', 'Uva', 'Naranja', 'Pimienta',
    'Papa', 'Frambuesa', 'Soja', 'Fresa', 'Tomate',
  ];

  // ── Animaciones ────────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── Mensajes guía ciclicos ─────────────────────────────────────────────────
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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
      _cameraController = null;
      if (mounted) setState(() => _isCameraReady = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  // ── Cámara ────────────────────────────────────────────────────────────────
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      _cameraController?.dispose();
      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
      });
    } catch (e) {
      debugPrint('[DiagnosisPage] Error cámara: $e');
    }
  }

  Future<void> _reinitCamera() async {
    setState(() => _isCameraReady = false);
    await _cameraController?.dispose();
    _cameraController = null;
    await _initCamera();
  }

  void _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
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
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (_cameraController!.value.isTakingPicture) return;
    try {
      final image = await _cameraController!.takePicture();
      if (mounted) {
        _guideTimer?.cancel();
        _pulseController.stop();
        context.read<DiagnosisBloc>().add(DiagnosisPhotoCaptured(image.path));
      }
    } catch (e) {
      debugPrint('[DiagnosisPage] Error captura: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
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
    context.read<DiagnosisBloc>().add(const DiagnosisCameraIdle());
    await _reinitCamera();
    _pulseController.repeat(reverse: true);
    _startGuideTimer();
  }

  void _processWithAI() {
    context.read<DiagnosisBloc>().add(DiagnosisProcessRequested(
          cropName: _cropLabels[_selectedCropIndex],
          description: '',
          symptoms: const [],
        ));
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
    return BlocBuilder<DiagnosisBloc, DiagnosisState>(
      builder: (context, state) {
        final isCaptured = state is DiagnosisCaptured ||
            state is DiagnosisProcessing ||
            state is DiagnosisResult;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Fondo: imagen capturada o preview de cámara
              if (isCaptured && state is DiagnosisCaptured)
                Positioned.fill(
                  child: Image.file(
                    File(state.imagePath),
                    fit: BoxFit.cover,
                  ),
                )
              else if (_isCameraReady && _cameraController != null)
                Positioned.fill(child: CameraPreview(_cameraController!))
              else
                const Positioned.fill(
                  child: Center(
                    child: CircularProgressIndicator(color: _bracketGreen),
                  ),
                ),

              if (isCaptured)
                Positioned.fill(
                  child: Container(color: Colors.black.withValues(alpha: 0.35)),
                ),

              if (!isCaptured) _buildVignette(),

              _buildTopBar(),
              _buildFocusFrame(isCaptured),
              _buildBottomBar(isCaptured),
            ],
          ),
        );
      },
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
              onTap: () => Navigator.maybePop(context),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.arrow_back_outlined,
                    color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(child: _buildCropSelector()),
            const SizedBox(width: 4),
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
                  color:
                      _flashState == 1 ? AppColors.warmAmber : Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropSelector() {
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _cropLabels.length,
        itemBuilder: (context, i) {
          final isSelected = i == _selectedCropIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedCropIndex = i),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.forestGreen
                    : Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _cropLabels[i],
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ),
          );
        },
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
      child: Container(
        height: 100,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        color: Colors.black.withValues(alpha: 0.6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: isCaptured ? _retakePhoto : _openHistory,
              child: SizedBox(
                width: 56,
                height: 56,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCaptured
                          ? Icons.refresh_outlined
                          : Icons.access_time_outlined,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isCaptured ? 'Repetir' : 'Historial',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            isCaptured ? _buildAnalyzeButton() : _buildShutterButton(),
            GestureDetector(
              onTap: _pickFromGallery,
              child: SizedBox(
                width: 56,
                height: 56,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_outlined,
                        color: Colors.white.withValues(alpha: 0.7), size: 22),
                    const SizedBox(height: 4),
                    Text(
                      'Galería',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.6),
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

  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: _takePicture,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.35), width: 3),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
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
  bool shouldRepaint(covariant _CornerBracketPainter old) =>
      color != old.color;
}
