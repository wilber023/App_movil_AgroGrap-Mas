import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_due_inspection_activity_usecase.dart';
import 'diagnosis_camera_aprendiz_page.dart';

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

  @override
  void initState() {
    super.initState();
    _checkDueInspection();
  }

  @override
  void dispose() {
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

    // On error: show the main tab UI anyway (maquetado mode)

    return Scaffold(
      backgroundColor: AppColors.aSurface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(),

            // Internal tabs
            Container(
              color: AppColors.aSurface,
              child: Row(
                children: [
                  _TabItem(
                    label: 'Analizar',
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                  _TabItem(
                    label: 'Mis diagnósticos',
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
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
                  : const _MyDiagnosesTab(),
            ),
          ],
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
              'AgroGraph IA',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () {}),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.aOrange : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
              color: isSelected ? AppColors.aOnSurface : AppColors.aOnSurfaceVariant,
            ),
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
  bool _hasPhoto = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Context banner (pending inspection info)
          Container(
            decoration: BoxDecoration(
              color: AppColors.aWarningBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.aWarningBorder),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: AppColors.aOrange, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INSPECCIÓN PENDIENTE · SEMANA ${widget.nextWeek}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.aWarningText,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Maíz · Milpa Norte',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.aOnSurface),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tu plan indica que es momento de revisar tu cultivo.',
                        style: TextStyle(fontSize: 13, color: AppColors.aOnSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {},
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ir a inspección',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.aOrange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, color: AppColors.aOrange, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.aSurfaceVariant)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'O REALIZA UN DIAGNÓSTICO LIBRE',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.aOnSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.08,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.aSurfaceVariant)),
            ],
          ),

          const SizedBox(height: 20),

          // Photo upload area
          GestureDetector(
            onTap: () => setState(() => _hasPhoto = !_hasPhoto),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 160),
              decoration: BoxDecoration(
                color: AppColors.aSurfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.aOutlineVariant,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: _hasPhoto
                  ? Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 200,
                            color: AppColors.aSurfaceContainerHigh,
                            child: const Center(
                              child: Icon(Icons.image, size: 60, color: AppColors.aOnSurfaceVariant),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: GestureDetector(
                            onTap: () => setState(() => _hasPhoto = false),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
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
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.aPrimaryContainer.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_a_photo_outlined, color: AppColors.aPrimary, size: 28),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Fotografía lo que ves',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.aOnSurface),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Sube una foto clara de la hoja, fruto o tallo afectado.',
                            style: TextStyle(fontSize: 13, color: AppColors.aOnSurfaceVariant),
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
                  onPressed: () => setState(() => _hasPhoto = true),
                  icon: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 20),
                  label: const Text('Tomar foto', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.aOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _hasPhoto = true),
                  icon: const Icon(Icons.image_outlined, color: AppColors.aOrange, size: 20),
                  label: const Text('Elegir de galería', style: TextStyle(color: AppColors.aOrange, fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.aOrange, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Notes textarea
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Información adicional (opcional)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.05,
                  color: AppColors.aOnSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: widget.notesController,
                maxLines: 3,
                maxLength: 300,
                style: const TextStyle(fontSize: 14, color: AppColors.aOnSurface),
                decoration: InputDecoration(
                  hintText: 'Describe lo que observas...',
                  hintStyle: const TextStyle(color: AppColors.aOnSurfaceVariant),
                  filled: true,
                  fillColor: AppColors.aSurfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.aOutlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.aOutlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.aSecondary, width: 2),
                  ),
                  counterStyle: const TextStyle(fontSize: 11, color: AppColors.aOnSurfaceVariant),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _hasPhoto ? () {} : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.aOrange,
                disabledBackgroundColor: AppColors.aSurfaceVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                _hasPhoto ? 'Analizar foto' : 'Primero agrega una foto',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _hasPhoto ? Colors.white : AppColors.aOnSurfaceVariant,
                  letterSpacing: 0.05,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyDiagnosesTab extends StatelessWidget {
  const _MyDiagnosesTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.aSurfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.find_in_page_outlined, size: 36, color: AppColors.aOnSurfaceVariant),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin diagnósticos aún',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.aOnSurface),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tus diagnósticos anteriores\naparecerán aquí.',
            style: TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
