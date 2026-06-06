import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class DiagnosisPage extends StatefulWidget {
  const DiagnosisPage({super.key});

  @override
  State<DiagnosisPage> createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<DiagnosisPage> {
  CameraController? _cameraController;
  bool _isFlashOn = false;
  bool _isCameraReady = false;
  int _selectedCropIndex = 0;
  final List<String> _crops = ['Maiz', 'Frijol', 'Jitomate', 'Chile', 'Papa'];

  @override
  void initState() {
    super.initState();
    _initCamera();
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
        if (mounted) {
          setState(() {
            _isCameraReady = true;
          });
        }
      }
    } catch (e) {
      // Manejo de excepcion si el hardware no esta disponible
      debugPrint('Error al inicializar la camara: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
        setState(() {
          _isFlashOn = false;
        });
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
        setState(() {
          _isFlashOn = true;
        });
      }
    } catch (e) {
      debugPrint('Error al configurar el flash: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (mounted) {
          _showDescriptionDialog(image.path);
        }
      }
    } catch (e) {
      debugPrint('Error al seleccionar imagen de la galeria: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_cameraController!.value.isTakingPicture) return;

    try {
      final XFile image = await _cameraController!.takePicture();
      if (mounted) {
        _showDescriptionDialog(image.path);
      }
    } catch (e) {
      debugPrint('Error al capturar la foto: $e');
    }
  }

  void _showDescriptionDialog(String imagePath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Describir el problema',
                style: AppTypography.tituloMd.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 16),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ej: Manchas amarillas en las hojas inferiores...',
                  hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Procesando evaluacion de IA...'),
                        backgroundColor: AppColors.forestGreen,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Procesar evaluacion rapida de IA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHistoryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Historial de evaluaciones de la IA',
                style: AppTypography.tituloMd.copyWith(color: AppColors.onSurface),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildHistoryItem('Tomate - Tizon tardio', 'Ayer, 14:30', AppColors.error),
                    _buildHistoryItem('Maiz - Gusano cogollero', '3 Jun 2026', AppColors.warmAmber),
                    _buildHistoryItem('Papa - Sano', '28 May 2026', AppColors.forestGreen),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryItem(String title, String date, Color statusColor) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
      ),
      title: Text(title, style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
      subtitle: Text(date, style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vista de Camara
          if (_isCameraReady && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.forestGreen),
              ),
            ),

          // Marco de enfoque central simulado
          Positioned.fill(
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.8), width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, color: Colors.white.withValues(alpha: 0.5), size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Enfoca la hoja afectada',
                      style: AppTypography.bodyMd.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Controles Superiores
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                // Selector de Cultivo (opcional pero contextual)
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _crops.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _selectedCropIndex;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCropIndex = index),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.forestGreen : Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                _crops[index],
                                style: AppTypography.labelMd.copyWith(
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // CONTROL REAL DEL FLASH
                IconButton(
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _isFlashOn ? AppColors.warmAmber : Colors.white,
                    size: 28,
                  ),
                  onPressed: _toggleFlash,
                ),
              ],
            ),
          ),

          // Controles Inferiores
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // MODAL DE DESCRIPCION E HISTORIAL
                IconButton(
                  icon: const Icon(Icons.history_rounded, color: Colors.white, size: 32),
                  onPressed: _showHistoryModal,
                ),

                // BOTON CENTRAL DE CAPTURA
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
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

                // CARGA DESDE LA GALERIA
                IconButton(
                  icon: const Icon(Icons.image_outlined, color: Colors.white, size: 32),
                  onPressed: _pickFromGallery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
