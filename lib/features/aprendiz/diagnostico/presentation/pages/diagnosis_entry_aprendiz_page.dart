import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../cultivo/domain/usecases/get_due_inspection_activity_usecase.dart';
import '../bloc/aprendiz_diagnosis_history_cubit.dart';
import '../bloc/diagnosis_camera_aprendiz_cubit.dart';
import '../widgets/diagnosis_analyze_submit_button.dart';
import '../widgets/diagnosis_analyzing_overlay.dart';
import '../widgets/diagnosis_capture_area.dart';
import '../widgets/diagnosis_capture_buttons_row.dart';
import '../widgets/diagnosis_confidence_indicator.dart';
import '../widgets/diagnosis_description_field.dart';
import '../widgets/diagnosis_educational_footnote.dart';
import '../widgets/diagnosis_entry_tab_item.dart';
import '../widgets/diagnosis_entry_top_bar.dart';
import '../widgets/diagnosis_history_list.dart';
import '../widgets/diagnosis_learning_section.dart';
import '../widgets/diagnosis_pending_inspection_banner.dart';
import '../widgets/diagnosis_tips_card.dart';
import 'diagnosis_camera_aprendiz_page.dart';
import 'diagnosis_result_aprendiz_page.dart';

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
              DiagnosisEntryTopBar(onInfoTap: _showInfoDialog),

              // Internal tabs
              Container(
                color: AppColors.aSurfaceContainerLowest,
                child: Row(
                  children: [
                    DiagnosisEntryTabItem(
                      icon: Icons.eco_outlined,
                      label: 'Analizar',
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                    DiagnosisEntryTabItem(
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
                  if (widget.hasPendingInspection)
                    DiagnosisPendingInspectionBanner(nextWeek: widget.nextWeek),

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

                  DiagnosisCaptureButtonsRow(
                    isEnabled: !isAnalyzing,
                    onTakePhoto: _takePhoto,
                    onPickGallery: _pickFromGallery,
                  ),

                  const SizedBox(height: AppSpacing.hugePlus),

                  // Mejora 3: campo de descripción con propósito educativo
                  DiagnosisDescriptionField(
                    controller: widget.notesController,
                    isEnabled: !isAnalyzing,
                  ),

                  const SizedBox(height: AppSpacing.huge),

                  DiagnosisAnalyzeSubmitButton(
                    hasPhoto: _hasPhoto,
                    isAnalyzing: isAnalyzing,
                    onPressed: _analyzeCrop,
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
            if (isAnalyzing) const DiagnosisAnalyzingOverlay(),
          ],
        );
      },
    );
  }
}
