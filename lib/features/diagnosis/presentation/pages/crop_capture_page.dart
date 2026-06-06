import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/diagnosis_bloc.dart';

// Pantalla de captura de cultivo (Stitch: "Captura de Cultivo")
// Selector de tipo de cultivo, vista de camara simulada, boton de captura.

class CropCapturePage extends StatefulWidget {
  const CropCapturePage({super.key});

  @override
  State<CropCapturePage> createState() => _CropCapturePageState();
}

class _CropCapturePageState extends State<CropCapturePage> {
  int _selectedCropIndex = 0;
  final List<String> _crops = ['Maiz', 'Frijol', 'Jitomate', 'Chile', 'Papa'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Captura de Cultivo',
          style: AppTypography.tituloMd.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Banner offline
          _buildOfflineBanner(),
          // Selector de cultivo
          _buildCropSelector(),
          // Visor de camara
          Expanded(child: _buildCameraPreview()),
          // Controles inferiores
          _buildCaptureControls(),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.warmAmber,
      child: Row(
        children: [
          const Icon(Icons.signal_wifi_off_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'Sin senal - foto se guardara en cola',
            style: AppTypography.etiquetaSm.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCropSelector() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _crops.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCropIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCropIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.forestGreen : Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _crops[index],
                  style: AppTypography.labelMd.copyWith(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Placeholder de camara
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Enfoca la hoja afectada',
                style: AppTypography.bodyMd.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          // Marco de enfoque
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.forestGreen.withValues(alpha: 0.7),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Galeria
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              color: Colors.white70,
              size: 24,
            ),
          ),
          // Boton de captura
          GestureDetector(
            onTap: _onCapture,
            child: Container(
              width: 72,
              height: 72,
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
          // Flash
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.flash_auto_rounded,
              color: Colors.white70,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  void _onCapture() {
    // En produccion se tomara la foto con camera y se enviara la ruta.
    // Por ahora se simula el envio de un path de prueba.
    context
        .read<DiagnosisBloc>()
        .add(const DiagnosisAnalyzeRequested(imagePath: '/tmp/crop_sample.jpg'));
  }
}
