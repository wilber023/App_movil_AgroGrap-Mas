import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_due_inspection_activity_usecase.dart';
import '../bloc/aprendiz_diagnosis_history_cubit.dart';
import '../bloc/diagnosis_camera_aprendiz_cubit.dart';
import '../widgets/diagnosis_history_list.dart';
import 'diagnosis_camera_aprendiz_page.dart';
import 'diagnosis_result_aprendiz_page.dart';

// Tipografía Inter consistente con el resto de la app (ver AppTypography).
const String _kFont = 'Inter';

// Sombra sutil compartida por las cards de esta pantalla, para que todo el
// feature se sienta parte de un mismo sistema visual (ver diagnosis_result_aprendiz_page).
const List<BoxShadow> _kCardShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
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
              _TopBar(),

              // Internal tabs
              Container(
                color: AppColors.aSurfaceContainerLowest,
                child: Row(
                  children: [
                    _TabItem(
                      icon: Icons.psychology_outlined,
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
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.aPrimaryContainer,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () {}),
          const Expanded(
            child: Text(
              'Diagnóstico',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: _kFont, color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () {}),
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
                color: isSelected ? AppColors.aOrange : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.aOrange : AppColors.aOnSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 12,
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
              content: Text(state.message, style: const TextStyle(fontFamily: _kFont, color: Colors.white)),
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
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado educativo de la sección
                  const Text(
                    '¿Qué quieres analizar hoy?',
                    style: TextStyle(fontFamily: _kFont, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.aOnSurface),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toma una foto clara de la planta y te ayudamos a entender qué está pasando.',
                    style: TextStyle(fontFamily: _kFont, fontSize: 13, color: AppColors.aOnSurfaceVariant, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // Context banner (pending inspection info)
                  if (widget.hasPendingInspection) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.aWarningBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.aWarningBorder),
                        boxShadow: _kCardShadow,
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.event_note_rounded, color: AppColors.aOrange, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'INSPECCIÓN PENDIENTE · SEMANA ${widget.nextWeek}',
                                  style: const TextStyle(
                                    fontFamily: _kFont,
                                    fontSize: 11,
                                    color: AppColors.aWarningText,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tu plan indica que es momento de revisar tu cultivo.',
                                  style: TextStyle(fontFamily: _kFont, fontSize: 13, color: AppColors.aOnSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.aOutlineVariant)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'O REALIZA UN DIAGNÓSTICO LIBRE',
                            style: const TextStyle(
                              fontFamily: _kFont,
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
                    const SizedBox(height: 20),
                  ],

                  // Photo upload area
                  GestureDetector(
                    onTap: isAnalyzing ? null : _takePhoto,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 190),
                      decoration: BoxDecoration(
                        color: _hasPhoto ? AppColors.aSurfaceContainerLowest : AppColors.aMint,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _hasPhoto ? AppColors.aOutlineVariant : AppColors.aSecondaryContainer,
                          width: 2,
                        ),
                        boxShadow: _hasPhoto ? _kCardShadow : null,
                      ),
                      child: _hasPhoto
                          ? Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(_imagePath!),
                                    height: 210,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: GestureDetector(
                                    onTap: isAnalyzing ? null : () => setState(() => _imagePath = null),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(5),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 64, height: 64,
                                    decoration: const BoxDecoration(
                                      color: AppColors.aSecondaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add_a_photo_outlined, color: AppColors.aSecondary, size: 30),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Fotografía lo que ves',
                                    style: TextStyle(fontFamily: _kFont, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.aOnSurface),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Una foto clara de la hoja, fruto o tallo afectado',
                                    style: TextStyle(fontFamily: _kFont, fontSize: 13, color: AppColors.aOnSurfaceVariant),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Camera / Gallery buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isAnalyzing ? null : _takePhoto,
                          icon: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 20),
                          label: const Text('Tomar foto', style: TextStyle(fontFamily: _kFont, color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.aSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isAnalyzing ? null : _pickFromGallery,
                          icon: const Icon(Icons.image_outlined, color: AppColors.aSecondary, size: 20),
                          label: const Text('Galería', style: TextStyle(fontFamily: _kFont, color: AppColors.aSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.aSecondary, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Notes textarea
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cuéntanos qué observas (opcional)',
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.aOnSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: widget.notesController,
                        maxLines: 3,
                        maxLength: 300,
                        enabled: !isAnalyzing,
                        style: const TextStyle(fontFamily: _kFont, fontSize: 14, color: AppColors.aOnSurface),
                        decoration: InputDecoration(
                          hintText: 'Ej. Las hojas se ven amarillas desde hace unos días...',
                          hintStyle: const TextStyle(fontFamily: _kFont, color: AppColors.aOnSurfaceVariant),
                          filled: true,
                          fillColor: AppColors.aSurfaceContainerLowest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.aOutlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.aOutlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.aSecondary, width: 2),
                          ),
                          counterStyle: const TextStyle(fontFamily: _kFont, fontSize: 11, color: AppColors.aOnSurfaceVariant),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_hasPhoto && !isAnalyzing) ? _analyzeCrop : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.aOrange,
                        disabledBackgroundColor: AppColors.aSurfaceVariant,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isAnalyzing
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Analizando tu foto...',
                                  style: TextStyle(fontFamily: _kFont, fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ],
                            )
                          : Text(
                              _hasPhoto ? 'Analizar foto' : 'Primero agrega una foto',
                              style: TextStyle(
                                fontFamily: _kFont,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _hasPhoto ? Colors.white : AppColors.aOnSurfaceVariant,
                                letterSpacing: 0.1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Overlay ligero mientras se analiza, para reforzar que la app
            // está trabajando (además del estado del botón).
            if (isAnalyzing)
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.aPrimaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _kCardShadow,
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Estamos revisando tu foto con inteligencia artificial...',
                            style: TextStyle(fontFamily: _kFont, fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
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

