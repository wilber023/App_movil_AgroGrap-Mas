import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/di/injection_container.dart';
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
  String? _imagePath;
  final TextEditingController _descriptionController = TextEditingController();

  bool get _photoTaken => _imagePath != null;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 82,
    );
    if (image != null && mounted) {
      setState(() => _imagePath = image.path);
    }
  }

  Future<void> _pickFromGallery() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (image != null && mounted) {
      setState(() => _imagePath = image.path);
    }
  }

  void _analyzeCrop() {
    final path = _imagePath;
    if (path == null) return;
    final cubit = context.read<DiagnosisCameraAprendizCubit>();
    cubit.analyzeCrop(path, _descriptionController.text);
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
          backgroundColor: AppColors.aOnSurface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: AppColors.aOnPrimary,
            title: Text('Inspección semanal', style: AppTypography.labelMd.copyWith(color: AppColors.aOnPrimary)),
          ),
          body: Stack(
            children: [
              // Vista previa de la foto capturada o ícono guía mientras no hay foto
              if (_photoTaken)
                Positioned.fill(
                  child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                )
              else
                Center(
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.aOnPrimary.withValues(alpha: 0.5),
                    size: 100,
                  ),
                ),
              if (_photoTaken)
                Positioned.fill(
                  child: Container(color: AppColors.aOnSurface.withValues(alpha: 0.35)),
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
                  color: AppColors.aOnSurface.withValues(alpha: 0.55),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.aOrange),
                        const SizedBox(height: 14),
                        Text('Analizando tu foto...', style: AppTypography.labelMd.copyWith(color: AppColors.aOnPrimary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCameraOverlay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
        Text(
          'Fotografía la hoja o parte afectada · Semana ${widget.weekNumber}',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLg.copyWith(color: AppColors.aOnPrimary),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _takePhoto,
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.aOnPrimary, width: 4),
            ),
            child: Center(
              child: Container(
                height: 60,
                width: 60,
                decoration: const BoxDecoration(
                  color: AppColors.aOnPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _pickFromGallery,
          icon: Icon(Icons.photo_outlined, color: AppColors.aOnPrimary.withValues(alpha: 0.7), size: 18),
          label: Text('Elegir de galería', style: AppTypography.bodyMd.copyWith(color: AppColors.aOnPrimary.withValues(alpha: 0.7))),
        ),
        ],
      ),
    );
  }

  Widget _buildPreviewOverlay(bool isLoading) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.aOnPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¿Quieres agregar algún detalle? (opcional)',
            style: AppTypography.labelMd.copyWith(color: AppColors.aOnSurface.withValues(alpha: 0.87)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            enabled: !isLoading,
            decoration: InputDecoration(
              hintText: 'Ej. Las hojas se ven amarillas desde hace 3 días...',
              hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.aOnSurface.withValues(alpha: 0.38)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.aOnSurface.withValues(alpha: 0.12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.aOnSurface.withValues(alpha: 0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.aSecondary, width: 1.5),
              ),
              filled: true,
              fillColor: AppColors.aOnSurface.withValues(alpha: 0.05),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isLoading ? null : _analyzeCrop,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.aOrange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Analizar foto', style: AppTypography.labelMd.copyWith(color: AppColors.aOnPrimary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: isLoading ? null : () {
              setState(() {
                _imagePath = null;
                _descriptionController.clear();
              });
            },
            child: Text('Tomar otra foto', style: AppTypography.bodyMd.copyWith(color: AppColors.aOnSurface.withValues(alpha: 0.54))),
          ),
        ],
      ),
    );
  }
}
