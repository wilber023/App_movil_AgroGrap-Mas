import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/diagnosis_bloc.dart';
import 'diagnosis_processing_page.dart';
import 'diagnosis_history_page.dart';

// =============================================================================
// AgroGraph-MAS -- Camara de Diagnostico (fullscreen)
// =============================================================================
// Pantalla principal del tab Diagnostico. Preview de camara a pantalla completa
// con controles flotantes, selector de cultivo con contexto de parcelas,
// marco de enfoque animado con corner brackets, panel de descripcion y
// chips de sintomas rapidos.
// =============================================================================

const Color _textPrimary = Color(0xFF1B2D27);
const Color _textSecondary = Color(0xFF6B8F71);
const Color _hintColor = Color(0xFFADB5BD);
const Color _chipGreenBg = Color(0xFFEAF3DE);
const Color _chipGreenText = Color(0xFF2D6A4F);
const Color _chipNeutralBg = Color(0xFFF1F1F1);
const Color _chipNeutralText = Color(0xFF888888);
const Color _bracketGreen = Color(0xFF52B788);
const Color _trackGrey = Color(0xFFE2EBE6);

/// Modelo local para un chip de cultivo en el selector.
class _CropChip {
  final String label;
  final String? parcelName; // null = secondary fallback chip
  final bool isPrimary;

  const _CropChip({
    required this.label,
    this.parcelName,
    this.isPrimary = false,
  });
}

class DiagnosisPage extends StatefulWidget {
  const DiagnosisPage({super.key});

  @override
  State<DiagnosisPage> createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<DiagnosisPage>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraReady = false;

  // Flash state: 0=off, 1=on, 2=auto
  int _flashState = 0;

  // Crop selection
  int _selectedCropIndex = 0;



  // Description panel
  final _descController = TextEditingController();
  final Set<int> _selectedSymptoms = {};

  // Corner bracket pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Simulated parcel-linked crops (primary) and fallback crops (secondary)
  static const List<_CropChip> _crops = [
    _CropChip(label: 'Maiz', parcelName: 'Milpa Norte', isPrimary: true),
    _CropChip(label: 'Jitomate', parcelName: 'Huerta Baja', isPrimary: true),
    _CropChip(label: 'Frijol'),
    _CropChip(label: 'Chile'),
    _CropChip(label: 'Papa'),
    _CropChip(label: 'Calabaza'),
  ];

  static const List<String> _symptomLabels = [
    'Manchas amarillas',
    'Hojas secas',
    'Tallo podrido',
    'Insectos visibles',
    'Raiz afectada',
    'Color anormal',
  ];

  @override
  void initState() {
    super.initState();
    _initCamera();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) setState(() => _isCameraReady = true);
      }
    } catch (e) {
      debugPrint('Error al inicializar camara: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final nextState = (_flashState + 1) % 3;
      switch (nextState) {
        case 0:
          await _cameraController!.setFlashMode(FlashMode.off);
          break;
        case 1:
          await _cameraController!.setFlashMode(FlashMode.torch);
          break;
        case 2:
          await _cameraController!.setFlashMode(FlashMode.auto);
          break;
      }
      setState(() => _flashState = nextState);
    } catch (e) {
      debugPrint('Error al configurar flash: $e');
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
        _pulseController.stop();
        context.read<DiagnosisBloc>().add(DiagnosisPhotoCaptured(image.path));
      }
    } catch (e) {
      debugPrint('Error al capturar foto: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        _pulseController.stop();
        context.read<DiagnosisBloc>().add(DiagnosisPhotoCaptured(image.path));
      }
    } catch (e) {
      debugPrint('Error al seleccionar imagen de galeria: $e');
    }
  }

  void _retakePhoto() {
    setState(() {
      _descController.clear();
      _selectedSymptoms.clear();
    });
    _pulseController.repeat(reverse: true);
    context.read<DiagnosisBloc>().add(const DiagnosisCameraIdle());
  }

  void _processWithAI() {
    final selectedCrop = _crops[_selectedCropIndex];
    final symptoms = _selectedSymptoms.map((i) => _symptomLabels[i]).toList();
    
    context.read<DiagnosisBloc>().add(DiagnosisProcessRequested(
      cropName: selectedCrop.label,
      parcelName: selectedCrop.parcelName,
      description: _descController.text.trim(),
      symptoms: symptoms,
    ));
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DiagnosisProcessingPage(),
      ),
    );
  }

  void _appendSymptom(int index) {
    final symptom = _symptomLabels[index];
    setState(() {
      if (_selectedSymptoms.contains(index)) {
        _selectedSymptoms.remove(index);
      } else {
        _selectedSymptoms.add(index);
        final current = _descController.text;
        if (current.isNotEmpty && !current.endsWith('. ') && !current.endsWith('.')) {
          _descController.text = '$current. $symptom';
        } else if (current.isNotEmpty) {
          _descController.text = '$current $symptom';
        } else {
          _descController.text = symptom;
        }
        _descController.selection = TextSelection.fromPosition(
          TextPosition(offset: _descController.text.length),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiagnosisBloc, DiagnosisState>(
      builder: (context, state) {
        final bool isCaptured = state is DiagnosisCaptured || state is DiagnosisProcessing || state is DiagnosisResult;
        
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Camara fullscreen o imagen capturada
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

              // Capa oscura si esta capturada
              if (isCaptured)
                Positioned.fill(
                  child: Container(color: Colors.black.withValues(alpha: 0.3)),
                ),

              // Top bar con selector de cultivo y flash
              _buildTopBar(),

              // Marco de enfoque animado
              _buildFocusFrame(isCaptured),

              // Bottom bar con controles de captura
              _buildBottomBar(isCaptured),

              // Panel de descripcion (solo cuando hay foto capturada)
              if (isCaptured) _buildDescriptionPanel(),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TOP BAR: Back, crop selector, flash
  // ---------------------------------------------------------------------------
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
            // Back
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.arrow_back_outlined, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 4),
            // Crop selector
            Expanded(child: _buildCropSelector()),
            const SizedBox(width: 4),
            // Flash
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
                  color: _flashState == 1 ? AppColors.warmAmber : Colors.white,
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
    // Separate primary and secondary
    final primaryCrops = _crops.where((c) => c.isPrimary).toList();
    final secondaryCrops = _crops.where((c) => !c.isPrimary).toList();

    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _crops.length + (primaryCrops.isNotEmpty && secondaryCrops.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          // Separator between primary and secondary
          if (primaryCrops.isNotEmpty &&
              secondaryCrops.isNotEmpty &&
              index == primaryCrops.length) {
            return Container(
              width: 1,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              color: Colors.white.withValues(alpha: 0.2),
            );
          }

          final cropIndex = index > primaryCrops.length && primaryCrops.isNotEmpty
              ? index - 1
              : index;
          if (cropIndex >= _crops.length) return const SizedBox.shrink();

          final crop = _crops[cropIndex];
          final isSelected = cropIndex == _selectedCropIndex;

          return GestureDetector(
            onTap: () => setState(() => _selectedCropIndex = cropIndex),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.forestGreen
                    : crop.isPrimary
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (crop.isPrimary) ...[
                    Icon(
                      Icons.eco_outlined,
                      size: 10,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    crop.isPrimary ? (crop.parcelName ?? crop.label) : crop.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : crop.isPrimary
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FOCUS FRAME: animated corner brackets
  // ---------------------------------------------------------------------------
  Widget _buildFocusFrame(bool isCaptured) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final frameWidth = screenWidth * 0.75;
    final frameHeight = screenHeight * 0.55;

    return Positioned.fill(
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final scale = isCaptured ? 1.0 : _pulseAnimation.value;
            final bracketColor = isCaptured ? AppColors.warmAmber : _bracketGreen;
            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: frameWidth,
                height: frameHeight,
                child: CustomPaint(
                  painter: _CornerBracketPainter(
                    color: bracketColor.withValues(
                      alpha: isCaptured ? 1.0 : _pulseAnimation.value,
                    ),
                    armLength: 24,
                    strokeWidth: 3,
                  ),
                  child: !isCaptured
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 24,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enfoca la hoja o tallo afectado',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
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

  // ---------------------------------------------------------------------------
  // BOTTOM BAR: Historial, shutter, Galeria
  // ---------------------------------------------------------------------------
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
            // Left: Historial / Repetir
            GestureDetector(
              onTap: isCaptured ? _retakePhoto : _openHistory,
              child: SizedBox(
                width: 48,
                height: 48,
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
            // Center: Shutter / Analizar
            isCaptured ? _buildAnalyzeButton() : _buildShutterButton(),
            // Right: Galeria
            GestureDetector(
              onTap: _pickFromGallery,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_outlined,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Galeria',
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
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
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
    );
  }

  Widget _buildAnalyzeButton() {
    return GestureDetector(
      onTap: _processWithAI,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warmAmber,
            ),
            child: const Icon(Icons.check_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 2),
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

  // ---------------------------------------------------------------------------
  // DESCRIPTION PANEL (bottom sheet after capture)
  // ---------------------------------------------------------------------------
  Widget _buildDescriptionPanel() {
    return Positioned(
      bottom: 100 + MediaQuery.of(context).padding.bottom,
      left: 0,
      right: 0,
      child: Container(
        height: 260,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: _trackGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Describe el problema (opcional)',
                style: AppTypography.labelMd.copyWith(
                  color: _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Anadir contexto mejora la precision del diagnostico.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              // Textarea
              Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.forestGreen, width: 0.5),
                ),
                child: Stack(
                  children: [
                    TextField(
                      controller: _descController,
                      maxLines: 3,
                      maxLength: 200,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: _textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Ej. Las hojas se estan poniendo amarillas desde hace 3 dias, aparecen manchas oscuras en los bordes...',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: _hintColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                        counterText: '',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 8,
                      child: Text(
                        '${_descController.text.length} / 200',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: _hintColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Quick context chips
              Text(
                'Sintomas visibles:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(_symptomLabels.length, (i) {
                  final isSelected = _selectedSymptoms.contains(i);
                  return GestureDetector(
                    onTap: () => _appendSymptom(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? _chipGreenBg : _chipNeutralBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _symptomLabels[i],
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? _chipGreenText : _chipNeutralText,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              // CTA
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _processWithAI,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.memory_outlined, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Procesar diagnostico con IA',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
        builder: (context, scrollController) {
          return DiagnosisHistorySheet(scrollController: scrollController);
        },
      ),
    );
  }
}

// =============================================================================
// Corner bracket painter (animated corners only, no full rectangle)
// =============================================================================
class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double armLength;
  final double strokeWidth;

  _CornerBracketPainter({
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

    // Top-left
    canvas.drawLine(Offset(0, a), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(a, 0), paint);

    // Top-right
    canvas.drawLine(Offset(w - a, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, a), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, h - a), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(a, h), paint);

    // Bottom-right
    canvas.drawLine(Offset(w, h - a), Offset(w, h), paint);
    canvas.drawLine(Offset(w - a, h), Offset(w, h), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) =>
      color != oldDelegate.color;
}
