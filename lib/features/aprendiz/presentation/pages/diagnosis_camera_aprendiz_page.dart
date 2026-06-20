import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/diagnosis_camera_aprendiz_cubit.dart';
import 'diagnosis_result_aprendiz_page.dart';

class DiagnosisCameraAprendizPage extends StatelessWidget {
  final int weekNumber;
  final String activityId;

  const DiagnosisCameraAprendizPage({
    super.key,
    required this.weekNumber,
    required this.activityId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DiagnosisCameraAprendizCubit>(),
      child: _DiagnosisCameraAprendizView(
        weekNumber: weekNumber,
        activityId: activityId,
      ),
    );
  }
}

class _DiagnosisCameraAprendizView extends StatefulWidget {
  final int weekNumber;
  final String activityId;

  const _DiagnosisCameraAprendizView({
    required this.weekNumber,
    required this.activityId,
  });

  @override
  State<_DiagnosisCameraAprendizView> createState() => _DiagnosisCameraAprendizViewState();
}

class _DiagnosisCameraAprendizViewState extends State<_DiagnosisCameraAprendizView> {
  bool _photoTaken = false;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _takePhoto() {
    setState(() {
      _photoTaken = true;
    });
  }

  void _analyzeCrop() {
    final cubit = context.read<DiagnosisCameraAprendizCubit>();
    // Usamos una ruta de imagen ficticia para el demo, igual que antes,
    // pero ahora se pasa por el Cubit real.
    cubit.analyzeCrop('path/to/mock_image.jpg', _descriptionController.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DiagnosisCameraAprendizCubit, DiagnosisCameraAprendizState>(
      listener: (context, state) {
        if (state is DiagnosisCameraAprendizSuccess) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DiagnosisResultAprendizPage(
                diagnosis: state.diagnosis,
                activityId: widget.activityId,
              ),
            ),
          );
        } else if (state is DiagnosisCameraAprendizError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is DiagnosisCameraAprendizLoading;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
            title: const Text('Inspección de Cultivo'),
          ),
          body: Stack(
            children: [
              // Mock Camera View / Preview
              Center(
                child: Icon(
                  _photoTaken ? Icons.image_rounded : Icons.camera_alt_rounded, 
                  color: Colors.white.withValues(alpha: 0.5), 
                  size: 100
                ),
              ),
              
              // Overlay UI
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: _photoTaken ? _buildPreviewOverlay(isLoading) : _buildCameraOverlay(),
              ),

              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.forestGreen),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCameraOverlay() {
    return Column(
      children: [
        Text(
          'Apunta a la hoja afectada (Semana ${widget.weekNumber})',
          style: AppTypography.bodyLg.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _takePhoto,
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: Container(
                height: 60,
                width: 60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewOverlay(bool isLoading) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¿Quieres agregar algún detalle? (opcional)',
            style: AppTypography.labelMd.copyWith(color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            enabled: !isLoading,
            decoration: InputDecoration(
              hintText: 'Ej. Las hojas se ven amarillas desde hace 3 días...',
              hintStyle: AppTypography.bodyMd.copyWith(color: Colors.black38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.black12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.black12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.green),
              ),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.05),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isLoading ? null : _analyzeCrop,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Analizar', style: AppTypography.labelMd.copyWith(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: isLoading ? null : () {
              setState(() {
                _photoTaken = false;
                _descriptionController.clear();
              });
            },
            child: Text('Tomar otra foto', style: AppTypography.bodyMd.copyWith(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
