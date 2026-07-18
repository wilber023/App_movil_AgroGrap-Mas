import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../cultivo/domain/usecases/get_due_inspection_activity_usecase.dart';
import '../bloc/aprendiz_diagnosis_history_cubit.dart';
import '../bloc/diagnosis_camera_aprendiz_cubit.dart';
import '../widgets/diagnosis_capture_area.dart';
import '../widgets/diagnosis_confidence_indicator.dart';
import '../widgets/diagnosis_description_field.dart';
import '../widgets/diagnosis_educational_footnote.dart';
import '../widgets/diagnosis_history_list.dart';
import '../widgets/diagnosis_learning_section.dart';
import '../widgets/diagnosis_tips_card.dart';
import 'diagnosis_camera_aprendiz_page.dart';
import 'diagnosis_result_aprendiz_page.dart';

/// Sombra sutil compartida por las cards de esta pantalla, para que todo el
/// feature se sienta parte de un mismo sistema visual (ver diagnosis_result_aprendiz_page).
final List<BoxShadow> _kCardShadow = [
  BoxShadow(color: AppColors.aOnSurface.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
];

class DiagnosisEntryAprendizPage extends StatefulWidget {
  const DiagnosisEntryAprendizPage({super.key});

  @override
  State<DiagnosisEntryAprendizPage> createState() => _DiagnosisEntryAprendizPageState();
}

class _DiagnosisEntryAprendizPageState extends State<DiagnosisEntryAprendizPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  int _nextWeek = 1;
  DateTime? _nextDate;
  bool _hasPendingInspection = false;
  int _selectedTab = 0;

  final _notesController = TextEditingController();

  // Se crea una sola vez y se conserva mientras la página vive (la página
  // permanece montada dentro del IndexedStack de AprendizMainShell), para
  // poder forzar una recarga cada vez que el usuario abre "Mis diagnósticos"
  // — así el diagnóstico recién analizado siempre aparece, sin depender de
  // que la pestaña se reconstruya desde cero.
  late final AprendizDiagnosisHistoryCubit _historyCubit;

  @override
  void initState() {
    super.initState();
    _historyCubit = sl<AprendizDiagnosisHistoryCubit>()..loadHistory();
    _checkDueInspection();
  }

  @override
  void dispose() {
    _historyCubit.close();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkDueInspection() async {
    final useCase = sl<GetDueInspectionActivityUseCase>();
    final result = await useCase(const NoParams());

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
        });
      },
      (dueActivity) async {
        if (dueActivity != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DiagnosisCameraAprendizPage(
                weekNumber: dueActivity.weekNumber,
                activityId: dueActivity.id,
              ),
            ),
          );
        } else {
          setState(() {
            _isLoading = false;
            _hasPendingInspection = false;
            _nextWeek = 2;
            _nextDate = DateTime.now().add(const Duration(days: 7));
          });
        }
      },
    );
  }

  void _showInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.aSurfaceContainerLowest,
        title: Text('¿Cómo funciona?', style: AppTypography.agendaSectionTitle.copyWith(color: AppColors.aOnSurface)),
        content: Text(
          'Toma o elige una foto clara de la parte afectada de tu planta. '
          'La analizamos para ayudarte a entender qué podría estar pasando y qué hacer al respecto. '
          'Los resultados tienen fines educativos y no sustituyen la evaluación de un especialista.',
          style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendido', style: AppTypography.labelMd.copyWith(color: AppColors.aSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.aMint,
        body: Center(child: CircularProgressIndicator(color: AppColors.aSecondary)),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<DiagnosisCameraAprendizCubit>()),
        BlocProvider.value(value: _historyCubit),
      ],
      child: Scaffold(
        backgroundColor: AppColors.aMint,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _TopBar(onInfoTap: _showInfoDialog),

              // Internal tabs
              Container(
                color: AppColors.aSurfaceContainerLowest,
                child: Row(
                  children: [
                    _TabItem(
                      icon: Icons.eco_outlined,
                      label: 'Analizar',
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                    _TabItem(
                      icon: Icons.history_rounded,
                      label: 'Mis diagnósticos',
                      isSelected: _selectedTab == 1,
                      onTap: () {
                        // Recarga siempre al entrar a la pestaña, para que un
                        // diagnóstico recién analizado aparezca de inmediato.
                        _historyCubit.loadHistory();
                        setState(() => _selectedTab = 1);
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _selectedTab == 0
                    ? _AnalyzeTab(
                        hasPendingInspection: _hasPendingInspection,
                        nextWeek: _nextWeek,
                        nextDate: _nextDate,
                        notesController: _notesController,
                      )
                    : const DiagnosisHistoryList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onInfoTap;
  const _TopBar({required this.onInfoTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.aPrimaryContainer,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.menu, color: AppColors.aOnPrimary), onPressed: () {}),
          Expanded(
            child: Text(
              'Diagnóstico',
              textAlign: TextAlign.center,
              style: AppTypography.agendaTitle.copyWith(color: AppColors.aOnPrimary, fontSize: 19),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.aOnPrimary),
            onPressed: onInfoTap,
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.aOrange : AppColors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.aOrange : AppColors.aOnSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.etiquetaSm.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: 0.1,
                  color: isSelected ? AppColors.aOnSurface : AppColors.aOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyzeTab extends StatefulWidget {
  final bool hasPendingInspection;
  final int nextWeek;
  final DateTime? nextDate;
  final TextEditingController notesController;

  const _AnalyzeTab({
    required this.hasPendingInspection,
    required this.nextWeek,
    required this.nextDate,
    required this.notesController,
  });

  @override
  State<_AnalyzeTab> createState() => _AnalyzeTabState();
}

class _AnalyzeTabState extends State<_AnalyzeTab> {
  String? _imagePath;

  bool get _hasPhoto => _imagePath != null;

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
    context.read<DiagnosisCameraAprendizCubit>().analyzeCrop(path, widget.notesController.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DiagnosisCameraAprendizCubit, DiagnosisCameraAprendizState>(
      listener: (context, state) {
        if (state is DiagnosisCameraAprendizSuccess) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DiagnosisResultAprendizPage(
                diagnosis: state.diagnosis,
                activityId: '',
              ),
            ),
          );
        } else if (state is DiagnosisCameraAprendizError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: AppTypography.agendaBody.copyWith(color: AppColors.aOnPrimary)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isAnalyzing = state is DiagnosisCameraAprendizLoading;

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxlPlus,
                AppSpacing.xxxl,
                AppSpacing.xxlPlus,
                AppSpacing.colossal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado educativo de la sección
                  Text(
                    '¿Qué quieres analizar hoy?',
                    style: AppTypography.agendaTitle.copyWith(color: AppColors.aOnSurface),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Toma una foto clara de la planta y te ayudamos a entender qué está pasando.',
                    style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.huge),

                  // Context banner (pending inspection info)
                  if (widget.hasPendingInspection) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.aWarningBg,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: AppColors.aWarningBorder),
                        boxShadow: _kCardShadow,
                      ),
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.event_note_rounded, color: AppColors.aOrange, size: 20),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'INSPECCIÓN PENDIENTE · SEMANA ${widget.nextWeek}',
                                  style: AppTypography.etiquetaSm.copyWith(
                                    color: AppColors.aWarningText,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Tu plan indica que es momento de revisar tu cultivo.',
                                  style: AppTypography.agendaBody.copyWith(color: AppColors.aOnSurfaceVariant, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.huge),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.aOutlineVariant)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                          child: Text(
                            'O REALIZA UN DIAGNÓSTICO LIBRE',
                            style: AppTypography.etiquetaSm.copyWith(
                              fontSize: 10,
                              color: AppColors.aOnSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.aOutlineVariant)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.huge),
                  ],

                  // Mejora 1: consejos para una mejor foto
                  const DiagnosisTipsCard(),
                  const SizedBox(height: AppSpacing.xxlPlus),

                  // Área de captura
                  DiagnosisCaptureArea(
                    imagePath: _imagePath,
                    isEnabled: !isAnalyzing,
                    onTap: _takePhoto,
                    onRemove: () => setState(() => _imagePath = null),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Camera / Gallery buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isAnalyzing ? null : _takePhoto,
                          icon: const Icon(Icons.photo_camera_outlined, color: AppColors.aOnPrimary, size: 20),
                          label: Text(
                            'Tomar foto',
                            style: AppTypography.labelMd.copyWith(color: AppColors.aOnPrimary, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.aSecondary,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isAnalyzing ? null : _pickFromGallery,
                          icon: const Icon(Icons.image_outlined, color: AppColors.aSecondary, size: 20),
                          label: Text(
                            'Galería',
                            style: AppTypography.labelMd.copyWith(color: AppColors.aSecondary, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.aSecondary, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.hugePlus),

                  // Mejora 3: campo de descripción con propósito educativo
                  DiagnosisDescriptionField(
                    controller: widget.notesController,
                    isEnabled: !isAnalyzing,
                  ),

                  const SizedBox(height: AppSpacing.huge),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_hasPhoto && !isAnalyzing) ? _analyzeCrop : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.aOrange,
                        disabledBackgroundColor: AppColors.aSurfaceVariant,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lgXl)),
                        elevation: 0,
                      ),
                      child: isAnalyzing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: AppColors.aOnPrimary, strokeWidth: 2),
                                ),
                                const SizedBox(width: AppSpacing.xl),
                                Text(
                                  'Analizando tu foto...',
                                  style: AppTypography.labelMd.copyWith(color: AppColors.aOnPrimary, fontSize: 15),
                                ),
                              ],
                            )
                          : Text(
                              _hasPhoto ? 'Analizar foto' : 'Primero agrega una foto',
                              style: AppTypography.labelMd.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _hasPhoto ? AppColors.aOnPrimary : AppColors.aOnSurfaceVariant,
                                letterSpacing: 0.1,
                              ),
                            ),
                    ),
                  ),

                  // Mejora 4 y 5: secciones preparadas para un resultado real.
                  // Sin datos, ambas permanecen ocultas (ver sus widgets).
                  const SizedBox(height: AppSpacing.xxlPlus),
                  const DiagnosisLearningSection(),
                  const DiagnosisConfidenceIndicator(),

                  // Mejora 7: nota educativa final
                  const SizedBox(height: AppSpacing.huge),
                  const DiagnosisEducationalFootnote(),
                ],
              ),
            ),

            // Overlay ligero mientras se analiza, para reforzar que la app
            // está trabajando (además del estado del botón).
            if (isAnalyzing)
              Positioned(
                top: AppSpacing.xl,
                left: AppSpacing.xxlPlus,
                right: AppSpacing.xxlPlus,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.aPrimaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.lgXl),
                      boxShadow: _kCardShadow,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: AppColors.aOnPrimary, strokeWidth: 2),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Text(
                            'Estamos revisando tu foto con inteligencia artificial...',
                            style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnPrimary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
