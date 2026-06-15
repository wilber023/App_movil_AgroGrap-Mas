import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/di/injection_container.dart';
import '../../../diagnosis/presentation/pages/diagnosis_page.dart';

// =============================================================================
// AgroGraph-MAS -- Agregar Parcela (formulario de un solo paso - MVP Simplificado)
// =============================================================================
// Colores clave: primary #2D6A4F, accent #F4A261, bg #F8FAF5.
// Formulario compacto, sin multi-step, offline-first, sin sombras.
// =============================================================================

const Color _bg = Color(0xFFF8FAF5);
const Color _textPrimary = Color(0xFF1B2D27);
const Color _textSecondary = Color(0xFF6B8F71);
const Color _hintColor = Color(0xFFADB5BD);

class AddParcelPage extends StatefulWidget {
  const AddParcelPage({super.key});

  @override
  State<AddParcelPage> createState() => _AddParcelPageState();
}

class _AddParcelPageState extends State<AddParcelPage> {
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedUnit = 'Hectáreas';
  int _selectedCropIndex = -1;
  DateTime? _selectedDate;

  // Campos adicionales opcionales (Acordeón)
  bool _isAdditionalExpanded = false;
  int _selectedTerrenoIndex = -1;
  final Set<int> _selectedSueloConditions = {};
  final Set<int> _selectedMalezaTypes = {};

  // Conectividad
  StreamSubscription? _connectivitySubscription;
  bool _isConnected = true;

  static const List<String> _crops = [
    'Maíz', 'Frijol', 'Jitomate', 'Chile', 'Papa', 'Calabaza', 'Otro',
  ];

  static const List<String> _terrenoOptions = [
    'Plano', 'Pendiente ligera', 'Pendiente pronunciada',
  ];

  static const List<String> _sueloOptions = [
    'Suelo seco', 'Suelo húmedo', 'Pedregoso', 'Compactado', 'Buen drenaje', 'No estoy seguro',
  ];

  static const List<String> _malezaOptions = [
    'Hoja ancha', 'Pastos', 'Ciperáceas', 'Mixta', 'No sé',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateState);
    _areaController.addListener(_updateState);
    _locationController.addListener(_updateState);

    _checkInitialConnection();
    _connectivitySubscription = sl<NetworkInfo>().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() {
          _isConnected = results.any((result) =>
              result == ConnectivityResult.wifi ||
              result == ConnectivityResult.mobile ||
              result == ConnectivityResult.ethernet);
        });
      }
    });
  }

  Future<void> _checkInitialConnection() async {
    final connected = await sl<NetworkInfo>().isConnected;
    if (mounted) {
      setState(() {
        _isConnected = connected;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _nameController.dispose();
    _areaController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _areaController.text.trim().isNotEmpty &&
      _locationController.text.trim().isNotEmpty &&
      _selectedCropIndex != -1 &&
      _selectedDate != null;

  String _estimatePhenologicalStage(DateTime date) {
    final daysPassed = DateTime.now().difference(date).inDays;
    if (daysPassed < 15) {
      return 'Emergencia';
    } else if (daysPassed < 45) {
      return 'Vegetativa';
    } else if (daysPassed < 90) {
      return 'Floración';
    } else {
      return 'Cosecha';
    }
  }

  void _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2D6A4F),
              onPrimary: Colors.white,
              onSurface: _textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  void _useCurrentLocation() {
    setState(() {
      _locationController.text = 'Tuxtla Gutiérrez, Chiapas';
    });
  }

  void _save() {
    if (!_isValid) return;
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
        backgroundColor: const Color(0xFF2D6A4F),
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
                  // Subtítulo
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 16),
                    child: Text(
                      'Completa solo la información que conozcas. Puedes editarla después.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ),

                  // Contenedor principal de campos requeridos
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _hintColor.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Campo 1: Nombre de la parcela
                        _buildFieldLabel('Nombre de la parcela'),
                        const SizedBox(height: 4),
                        _buildInput(
                          controller: _nameController,
                          hint: 'Ej. Milpa Norte',
                          icon: Icons.pin_drop_outlined,
                        ),
                        const SizedBox(height: 12),

                        // Campo 2: Superficie
                        _buildFieldLabel('Superficie'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              flex: 65,
                              child: _buildInput(
                                controller: _areaController,
                                hint: 'Ej. 2.5',
                                icon: Icons.straighten_outlined,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      color: _textPrimary,
                                      fontSize: 13,
                                    ),
                                    items: ['Hectáreas', 'm²']
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
                        const SizedBox(height: 12),

                        // Campo 3: Municipio y estado
                        _buildFieldLabel('Municipio y estado'),
                        const SizedBox(height: 4),
                        _buildInput(
                          controller: _locationController,
                          hint: 'Ej. Tuxtla Gutiérrez, Chiapas',
                          icon: Icons.map_outlined,
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _useCurrentLocation,
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.my_location_outlined,
                                    color: Color(0xFF2D6A4F), size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Usar mi ubicación',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF2D6A4F),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Campo 4: Cultivo principal
                        _buildFieldLabel('Cultivo principal'),
                        const SizedBox(height: 6),
                        _buildSingleSelector(
                          items: _crops,
                          selectedIndex: _selectedCropIndex,
                          onSelected: (i) => setState(() => _selectedCropIndex = i),
                        ),
                        const SizedBox(height: 12),

                        // Campo 5: Fecha de siembra
                        _buildFieldLabel('Fecha de siembra'),
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
                                  width: 0.5),
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
                                  style: TextStyle(
                                    fontFamily: 'Inter',
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
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF3DE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Etapa estimada: ${_estimatePhenologicalStage(_selectedDate!)}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: Color(0xFF27500A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ACORDEÓN: INFORMACIÓN ADICIONAL (OPCIONAL)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _hintColor.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() =>
                              _isAdditionalExpanded = !_isAdditionalExpanded),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Información adicional (opcional)',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1B2D27),
                                  ),
                                ),
                                Icon(
                                  _isAdditionalExpanded
                                      ? Icons.keyboard_arrow_up_outlined
                                      : Icons.keyboard_arrow_down_outlined,
                                  color: const Color(0xFF1B2D27),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isAdditionalExpanded) ...[
                          const Divider(height: 1, thickness: 0.5),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Campo 6: Tipo de terreno
                                _buildOptionalHeader(
                                  title: 'Tipo de terreno',
                                  subtitle: 'Ayuda a interpretar el comportamiento del cultivo y las aplicaciones.',
                                ),
                                const SizedBox(height: 6),
                                _buildSingleSelector(
                                  items: _terrenoOptions,
                                  selectedIndex: _selectedTerrenoIndex,
                                  onSelected: (i) => setState(() => _selectedTerrenoIndex = i),
                                ),
                                const SizedBox(height: 16),

                                // Campo 7: Condición del suelo
                                _buildOptionalHeader(
                                  title: 'Condición del suelo',
                                  subtitle: 'Selecciona la opción que mejor describa la parcela.',
                                ),
                                const SizedBox(height: 6),
                                _buildMultiSelector(
                                  items: _sueloOptions,
                                  selectedIndices: _selectedSueloConditions,
                                  onTap: (i) {
                                    setState(() {
                                      if (_selectedSueloConditions.contains(i)) {
                                        _selectedSueloConditions.remove(i);
                                      } else {
                                        _selectedSueloConditions.add(i);
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Campo 8: Maleza predominante
                                _buildOptionalHeader(
                                  title: 'Maleza predominante',
                                  subtitle: 'Puede ayudar a mejorar recomendaciones futuras.',
                                ),
                                const SizedBox(height: 6),
                                _buildMultiSelector(
                                  items: _malezaOptions,
                                  selectedIndices: _selectedMalezaTypes,
                                  onTap: (i) {
                                    setState(() {
                                      if (_selectedMalezaTypes.contains(i)) {
                                        _selectedMalezaTypes.remove(i);
                                      } else {
                                        _selectedMalezaTypes.add(i);
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // INFORMATION HINT
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3DE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF2D6A4F), size: 16),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Agregar información del terreno puede ayudar a generar recomendaciones más precisas.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: Color(0xFF27500A),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // OFFLINE NOTE
                  if (!_isConnected) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_off_outlined, color: Color(0xFFADB5BD), size: 16),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Sin conexión · se guardará localmente',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: Color(0xFFADB5BD),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 100), // Espacio para el CTA fijo
                ],
              ),
            ),
          ),

          // CTA FIJO (SMART CTA BEHAVIOR)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: _hintColor.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isValid ? _save : null,
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
                    backgroundColor: const Color(0xFFF4A261),
                    foregroundColor: const Color(0xFF4A2800),
                    disabledBackgroundColor: const Color(0xFFE2EBE6),
                    disabledForegroundColor: const Color(0xFFADB5BD),
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

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _textSecondary,
      ),
    );
  }

  Widget _buildOptionalHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: _hintColor,
          ),
        ),
      ],
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
        style: const TextStyle(
          fontFamily: 'Inter',
          color: _textPrimary,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Inter',
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
              color: Color(0xFF2D6A4F),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleSelector({
    required List<String> items,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
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
              color: isSelected ? const Color(0xFFEAF3DE) : const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: const Color(0xFF2D6A4F), width: 0.5)
                  : null,
            ),
            child: Text(
              items[i],
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF2D6A4F) : const Color(0xFF888888),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMultiSelector({
    required List<String> items,
    required Set<int> selectedIndices,
    required ValueChanged<int> onTap,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(items.length, (i) {
        final isSelected = selectedIndices.contains(i);
        return GestureDetector(
          onTap: () => onTap(i),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEAF3DE) : const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: const Color(0xFF2D6A4F), width: 0.5)
                  : null,
            ),
            child: Text(
              items[i],
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF2D6A4F) : const Color(0xFF888888),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// Overlay de éxito post-guardado
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
      color: const Color(0xFF2D6A4F),
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
                    color: Color(0xFF2D6A4F),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '¡Parcela registrada!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ahora puedes realizar tu primer diagnóstico cuando lo necesites.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
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
                      'Ir a diagnóstico →',
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
