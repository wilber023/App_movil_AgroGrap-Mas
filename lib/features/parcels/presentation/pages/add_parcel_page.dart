import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../diagnosis/presentation/pages/diagnosis_page.dart';

// =============================================================================
// AgroGraph-MAS -- Agregar Parcela (formulario de un solo paso)
// =============================================================================
// Colores clave: primary #2D6A4F, accent #F4A261, bg #F8FAF5.
// Formulario compacto, sin multi-step, offline-first, sin sombras.
// =============================================================================

const Color _bg = Color(0xFFF8FAF5);
const Color _textPrimary = Color(0xFF1B2D27);
const Color _textSecondary = Color(0xFF6B8F71);
const Color _hintColor = Color(0xFFADB5BD);
const Color _chipGreenBg = Color(0xFFEAF3DE);
const Color _chipGreenText = Color(0xFF27500A);
const Color _chipAlertBg = Color(0xFFFDECEA);
const Color _chipAlertText = Color(0xFFA32D2D);
const Color _chipNeutralBg = Color(0xFFF1F1F1);
const Color _chipNeutralText = Color(0xFF888888);
const Color _infoBg = Color(0xFFEAF3DE);
const Color _infoText = Color(0xFF27500A);
const Color _ctaBg = Color(0xFFF4A261);
const Color _ctaText = Color(0xFF4A2800);


class AddParcelPage extends StatefulWidget {
  const AddParcelPage({super.key});

  @override
  State<AddParcelPage> createState() => _AddParcelPageState();
}

class _AddParcelPageState extends State<AddParcelPage> {
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedUnit = 'Hectareas';
  int _selectedCropIndex = -1;
  int _selectedRiegoIndex = -1;
  final Set<int> _selectedDiseases = {};
  DateTime? _selectedDate;

  static const List<String> _crops = [
    'Maiz', 'Frijol', 'Jitomate', 'Chile', 'Papa', 'Calabaza', 'Otro',
  ];

  static const List<String> _riego = [
    'Temporal', 'Goteo', 'Aspersion', 'Sin riego',
  ];

  static const List<String> _diseases = [
    'Ninguno', 'Tizon', 'Cogollero', 'Antracnosis', 'Cenicilla', 'Otro',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  void _save() {
    // Simular guardado local offline-first
    _showSuccessOverlay();
  }

  void _showSuccessOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SuccessOverlay(
        onDiagnosis: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DiagnosisPage()),
          );
        },
        onViewParcels: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nueva Parcela',
          style: AppTypography.labelMd.copyWith(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtitulo
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 16),
                    child: Text(
                      'Registra los datos basicos para que el modelo de diagnosticos precisos.',
                      style: AppTypography.etiquetaSm.copyWith(
                        color: _textSecondary,
                      ),
                    ),
                  ),
                  // Formulario en tarjeta unica
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _hintColor.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Campo 1: Nombre
                        _fieldLabel('Nombre de la parcela'),
                        const SizedBox(height: 4),
                        _buildInput(
                          controller: _nameController,
                          hint: 'Ej. Milpa Norte',
                          icon: Icons.pin_drop_outlined,
                        ),
                        const SizedBox(height: 10),
                        // Campo 2: Superficie
                        _fieldLabel('Superficie'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              flex: 65,
                              child: _buildInput(
                                controller: _areaController,
                                hint: 'Ej. 2.5',
                                icon: Icons.straighten_outlined,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 35,
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _hintColor.withValues(alpha: 0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedUnit,
                                    isExpanded: true,
                                    style: AppTypography.etiquetaSm.copyWith(
                                      color: _textPrimary,
                                      fontSize: 13,
                                    ),
                                    items: ['Hectareas', 'm2']
                                        .map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e),
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => _selectedUnit = v);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Campo 3: Ubicacion
                        _fieldLabel('Municipio y estado'),
                        const SizedBox(height: 4),
                        _buildInput(
                          controller: _locationController,
                          hint: 'Ej. Tuxtla Gutierrez, Chiapas',
                          icon: Icons.map_outlined,
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {},
                          child: Row(
                            children: [
                              const Icon(Icons.my_location_outlined,
                                  color: AppColors.forestGreen, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'Usar mi ubicacion',
                                style: AppTypography.etiquetaSm.copyWith(
                                  color: AppColors.forestGreen,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Campo 4: Cultivo
                        _fieldLabel('Cultivo principal'),
                        const SizedBox(height: 4),
                        _buildChipSelector(
                          items: _crops,
                          selectedIndex: _selectedCropIndex,
                          onSelected: (i) => setState(() => _selectedCropIndex = i),
                          selectedBg: _chipGreenBg,
                          selectedText: AppColors.forestGreen,
                          selectedBorder: AppColors.forestGreen,
                        ),
                        const SizedBox(height: 10),
                        // Campo 5: Fecha de siembra
                        _fieldLabel('Fecha de siembra'),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _hintColor.withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    color: _textSecondary, size: 16),
                                const SizedBox(width: 10),
                                Text(
                                  _selectedDate != null
                                      ? '${_selectedDate!.day.toString().padLeft(2, '0')} / ${_selectedDate!.month.toString().padLeft(2, '0')} / ${_selectedDate!.year}'
                                      : 'DD / MM / AAAA',
                                  style: AppTypography.etiquetaSm.copyWith(
                                    color: _selectedDate != null
                                        ? _textPrimary
                                        : _hintColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_selectedDate != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _chipGreenBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Etapa estimada: Floracion',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: _chipGreenText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        // Campo 6: Sistema de riego
                        _fieldLabel('Sistema de riego'),
                        const SizedBox(height: 4),
                        _buildChipSelector(
                          items: _riego,
                          selectedIndex: _selectedRiegoIndex,
                          onSelected: (i) =>
                              setState(() => _selectedRiegoIndex = i),
                          selectedBg: _chipGreenBg,
                          selectedText: AppColors.forestGreen,
                          selectedBorder: AppColors.forestGreen,
                        ),
                        const SizedBox(height: 10),
                        // Campo 7: Historial de enfermedades
                        _fieldLabel('Problemas fitosanitarios previos'),
                        const SizedBox(height: 2),
                        Text(
                          'Ayuda al modelo a anticipar riesgos',
                          style: AppTypography.etiquetaSm.copyWith(
                            color: _hintColor,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildMultiChipSelector(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Info hint
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _infoBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.forestGreen, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Mas datos = diagnosticos mas precisos y mejores alternativas economicas.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: _infoText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80), // espacio para el CTA fijo
                ],
              ),
            ),
          ),
          // CTA fijo en la parte inferior
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: _hintColor.withValues(alpha: 0.3), width: 0.5),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_outlined, size: 18),
                  label: const Text(
                    'Guardar parcela',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ctaBg,
                    foregroundColor: _ctaText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Componentes de formulario
  // ---------------------------------------------------------------------------
  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _textSecondary,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: AppTypography.etiquetaSm.copyWith(
          color: _textPrimary,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.etiquetaSm.copyWith(
            color: _hintColor,
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: _textSecondary, size: 16),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: _hintColor.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: _hintColor.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.forestGreen,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChipSelector({
    required List<String> items,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    required Color selectedBg,
    required Color selectedText,
    required Color selectedBorder,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(items.length, (i) {
        final isSelected = i == selectedIndex;
        return GestureDetector(
          onTap: () => onSelected(i),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : _chipNeutralBg,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: selectedBorder, width: 0.5)
                  : null,
            ),
            child: Text(
              items[i],
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? selectedText : _chipNeutralText,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMultiChipSelector() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(_diseases.length, (i) {
        final isSelected = _selectedDiseases.contains(i);
        // "Ninguno" (index 0) usa estilo verde, enfermedades usan estilo rojo
        final isDisease = i > 0;
        return GestureDetector(
          onTap: () {
            setState(() {
              if (i == 0) {
                _selectedDiseases.clear();
                _selectedDiseases.add(0);
              } else {
                _selectedDiseases.remove(0);
                if (_selectedDiseases.contains(i)) {
                  _selectedDiseases.remove(i);
                } else {
                  _selectedDiseases.add(i);
                }
              }
            });
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDisease ? _chipAlertBg : _chipGreenBg)
                  : _chipNeutralBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _diseases[i],
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? (isDisease ? _chipAlertText : _chipGreenText)
                    : _chipNeutralText,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// Overlay de exito post-guardado
// =============================================================================
class _SuccessOverlay extends StatelessWidget {
  final VoidCallback onDiagnosis;
  final VoidCallback onViewParcels;

  const _SuccessOverlay({
    required this.onDiagnosis,
    required this.onViewParcels,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.forestGreen,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.forestGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '\u00A1Parcela registrada!',
                  style: AppTypography.labelMd.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ahora toma una foto para tu primer diagnostico.',
                  style: AppTypography.etiquetaSm.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onDiagnosis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4A261),
                      foregroundColor: const Color(0xFF4A2800),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Ir a diagnostico \u2192',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onViewParcels,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ver mis parcelas',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
