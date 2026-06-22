import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'aprendiz_crop_route_page.dart';

class AprendizCropRegisterPage extends StatefulWidget {
  const AprendizCropRegisterPage({super.key});

  @override
  State<AprendizCropRegisterPage> createState() => _AprendizCropRegisterPageState();
}

class _AprendizCropRegisterPageState extends State<AprendizCropRegisterPage> {
  int? _selectedCropIndex;
  DateTime? _sowingDate;
  final _areaController = TextEditingController();
  String _selectedUnit = 'Hectáreas';

  static const _crops = [
    ('🎃', 'Calabaza'),
    ('🫘', 'Frijol'),
    ('🍎', 'Manzana'),
    ('🫐', 'Mora'),
    ('🍒', 'Cereza'),
    ('🌽', 'Maíz'),
    ('🍑', 'Durazno'),
    ('🍇', 'Uva'),
    ('🍊', 'Naranja'),
    ('🫑', 'Pimienta'),
    ('🥔', 'Papa'),
    ('🍓', 'Frambuesa'),
    ('🌱', 'Soja'),
    ('🍓', 'Fresa'),
    ('🍅', 'Tomate'),
  ];

  static const _units = ['Hectáreas', 'm²', 'km²'];

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectedCropIndex != null &&
      _sowingDate != null &&
      _areaController.text.trim().isNotEmpty;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _sowingDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.aSecondary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _sowingDate = date);
  }

  DateTime? get _estimatedHarvest => _sowingDate?.add(const Duration(days: 18 * 7));

  void _submit() {
    if (!_canSubmit || !mounted) return;
    final cropName = _crops[_selectedCropIndex!].$2;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Cultivo registrado! Generando plan para $cropName...'),
        backgroundColor: AppColors.aSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AprendizCropRoutePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aMint,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              height: 56,
              color: AppColors.aPrimaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'AgroGraph IA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registra tu cultivo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.aPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Con estos 3 datos generamos tu plan de actividades automáticamente.',
                      style: TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant),
                    ),
                    const SizedBox(height: 24),

                    // Step 1: Crop selection
                    const _StepLabel(step: '①', label: '¿Qué vas a sembrar?'),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _crops.length,
                      itemBuilder: (context, i) {
                        final (emoji, name) = _crops[i];
                        final isSelected = _selectedCropIndex == i;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCropIndex = i),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.aSecondaryContainer
                                  : AppColors.aSurfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.aSecondary
                                    : AppColors.aOutlineVariant,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 26)),
                                const SizedBox(height: 4),
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.aSecondary
                                        : AppColors.aOnSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Step 2: Sowing date
                    const _StepLabel(step: '②', label: 'Fecha de siembra'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.aSurfaceContainerLowest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _sowingDate != null
                                ? AppColors.aSecondary
                                : AppColors.aOutlineVariant,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                color: AppColors.aOnSurfaceVariant, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _sowingDate == null
                                    ? 'Seleccionar fecha'
                                    : _formatDate(_sowingDate!),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _sowingDate == null
                                      ? AppColors.aOnSurfaceVariant
                                      : AppColors.aOnSurface,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppColors.aOnSurfaceVariant, size: 20),
                          ],
                        ),
                      ),
                    ),

                    if (_estimatedHarvest != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.aSecondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_available_outlined,
                                size: 16, color: AppColors.aSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Cosecha estimada: ${_formatDate(_estimatedHarvest!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.aSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Step 3: Area
                    const _StepLabel(step: '③', label: '¿Cuánta área tienes?'),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _areaController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Ej. 5',
                              hintStyle: const TextStyle(
                                  color: AppColors.aOnSurfaceVariant),
                              filled: true,
                              fillColor: AppColors.aSurfaceContainerLowest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.aOutlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.aOutlineVariant),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: AppColors.aSecondary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.aSurfaceContainerLowest,
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: AppColors.aOutlineVariant),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedUnit,
                              items: _units
                                  .map((u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(u,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: AppColors.aOnSurface)),
                                      ))
                                  .toList(),
                              onChanged: (u) =>
                                  setState(() => _selectedUnit = u!),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Info preview card
                    if (_canSubmit) ...[
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.aSecondaryContainer
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.aSecondaryContainer),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                color: AppColors.aSecondary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.aSecondary,
                                      height: 1.5),
                                  children: [
                                    TextSpan(
                                      text:
                                          'Tu plan generará 18 semanas de actividades para ${_crops[_selectedCropIndex!].$2}.\n',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const TextSpan(
                                      text:
                                          'Sin IA en este paso — son plantillas validadas por agrónomas.',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).viewPadding.bottom + 16),
        color: AppColors.aMint,
        child: ElevatedButton(
          onPressed: _canSubmit ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.aOrange,
            disabledBackgroundColor: AppColors.aSurfaceVariant,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: Text(
            _canSubmit ? '🌱  Generar mi plan →' : 'Completa los 3 pasos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color:
                  _canSubmit ? Colors.white : AppColors.aOnSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _StepLabel extends StatelessWidget {
  final String step;
  final String label;
  const _StepLabel({required this.step, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: AppColors.aSecondary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.aOnSurface),
        ),
      ],
    );
  }
}
