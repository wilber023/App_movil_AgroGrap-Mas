import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_due_inspection_activity_usecase.dart';
import '../../domain/usecases/get_crop_plan_progress_usecase.dart';
import 'diagnosis_camera_aprendiz_page.dart';

class DiagnosisEntryAprendizPage extends StatefulWidget {
  const DiagnosisEntryAprendizPage({super.key});

  @override
  State<DiagnosisEntryAprendizPage> createState() => _DiagnosisEntryAprendizPageState();
}

class _DiagnosisEntryAprendizPageState extends State<DiagnosisEntryAprendizPage> {
  bool _isLoading = true;
  String? _errorMessage;
  int _nextWeek = 1;
  DateTime? _nextDate;

  @override
  void initState() {
    super.initState();
    _checkDueInspection();
  }

  Future<void> _checkDueInspection() async {
    final useCase = sl<GetDueInspectionActivityUseCase>();
    final result = await useCase(const NoParams());
    
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (dueActivity) async {
        if (dueActivity != null) {
          // Si hay inspección pendiente, navegamos directamente
          // Usamos replacement para que al cerrar la cámara vuelva a inicio o no se acumule
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DiagnosisCameraAprendizPage(
                weekNumber: dueActivity.weekNumber,
                activityId: dueActivity.id,
              ),
            ),
          );
        } else {
          // No hay inspección hoy, buscamos datos del plan
          // TODO: Idealmente tener un GetNextInspectionDateUseCase, por ahora hardcodeamos 
          // basado en el week para cumplir la visualización si no existe.
          setState(() {
            _isLoading = false;
            _nextWeek = 2; // Simulado
            _nextDate = DateTime.now().add(const Duration(days: 7)); // Simulado
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.forestGreen)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Diagnóstico'), elevation: 0),
        body: ErrorStateWidget(
          message: _errorMessage!,
          onRetry: () {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            _checkDueInspection();
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico'),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.surfaceVariant,
                child: const Icon(Icons.calendar_month_rounded, size: 48, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Text(
                'No tienes una inspección\nprogramada por ahora',
                style: AppTypography.tituloLg.copyWith(color: AppColors.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Tu próxima inspección es en la Semana $_nextWeek · ${_formatDate(_nextDate ?? DateTime.now())}',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.forestGreen),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () {
                  // Redirige a Mi Cultivo. En el shell ya existe un estado _currentIndex.
                  // Idealmente esto se comunica mediante el gestor de estado para cambiar el index del shell.
                  // TODO: Implementar cambio de pestaña.
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.forestGreen,
                  side: const BorderSide(color: AppColors.forestGreen),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Ver mi ruta de cultivo →'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
