import 'dart:async';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/network/network_info.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/cultivo_entity.dart';
import '../../domain/repositories/parcel_repository.dart';
import '../../domain/usecases/get_cultivo_catalog_usecase.dart';
import '../../domain/value_objects/hectareas.dart';
import '../bloc/parcel_bloc.dart';
import '../../../diagnosis/presentation/pages/diagnosis_page.dart';

// =============================================================================
// AgroGraph-MAS -- Nueva Parcela / Cultivo
// Conectado al microservicio de cultivos via BLoC + real API.
// =============================================================================


class AddParcelPage extends StatefulWidget {
  const AddParcelPage({super.key});

  @override
  State<AddParcelPage> createState() => _AddParcelPageState();
}

class _AddParcelPageState extends State<AddParcelPage> {
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _regionController = TextEditingController();

  String _selectedUnit = 'Hectáreas';
  int _selectedCropIndex = -1;
  DateTime? _selectedDate;

  bool _isAdditionalExpanded = false;
  int _selectedTerrenoIndex = -1;
  final Set<int> _selectedSueloConditions = {};
  final Set<int> _selectedMalezaTypes = {};

  StreamSubscription? _connectivitySubscription;
  bool _isConnected = true;

  // Catálogo cargado desde el backend (vacío mientras carga)
  List<CultivoEntity> _catalog = [];
  bool _catalogLoading = false;

  static const List<String> _terrenoOptions = [
    'Plano',
    'Pendiente ligera',
    'Pendiente pronunciada',
  ];
  static const List<String> _sueloOptions = [
    'Seco',
    'Húmedo',
    'Pedregoso',
    'Arcilloso',
    'Bien drenado',
    'No estoy seguro',
  ];
  static const List<String> _malezaOptions = [
    'Hoja ancha',
    'Pastos',
    'Ciperáceas',
    'Mixta',
    'No hay / No sé',
  ];

  // Cultivos soportados por el modelo CNN
  static const Set<String> _allowedCrops = {
    'Calabaza',
    'Frijol',
    'Maíz',
    'Papa',
    'Tomate',
  };

  static const Map<String, String> _emojiMap = {
    'Calabaza': '🍈',
    'Frijol': '🫘',
    'Maíz': '🌽',
    'Papa': '🥔',
    'Tomate': '🍅',
  };

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateState);
    _areaController.addListener(_updateState);
    _regionController.addListener(_updateState);

    _checkInitialConnection();
    _connectivitySubscription = sl<NetworkInfo>().onConnectivityChanged.listen((
      results,
    ) {
      if (mounted) {
        setState(() {
          _isConnected = results.any(
            (r) =>
                r == ConnectivityResult.wifi ||
                r == ConnectivityResult.mobile ||
                r == ConnectivityResult.ethernet,
          );
        });
      }
    });

    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    if (mounted) setState(() => _catalogLoading = true);
    try {
      final result = await sl<GetCultivoCatalogUseCase>()(const NoParams());
      if (!mounted) return;
      result.fold(
        (_) => setState(() => _catalogLoading = false),
        (cultivos) => setState(() {
          _catalog = cultivos
              .where((c) => _allowedCrops.contains(c.nombre))
              .toList();
          _catalogLoading = false;
        }),
      );
    } catch (_) {
      if (mounted) setState(() => _catalogLoading = false);
    }
  }

  Future<void> _checkInitialConnection() async {
    final connected = await sl<NetworkInfo>().isConnected;
    if (mounted) setState(() => _isConnected = connected);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _nameController.dispose();
    _areaController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  void _updateState() => setState(() {});

  String? get _areaError => Hectareas.validate(_areaController.text);

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _areaError == null &&
      _regionController.text.trim().isNotEmpty &&
      _selectedCropIndex != -1 &&
      _selectedDate != null &&
      _catalog.isNotEmpty;

  String _estimatePhenologicalStage(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days < 15) return 'Emergencia';
    if (days < 45) return 'Vegetativa';
    if (days < 90) return 'Floración';
    return 'Cosecha';
  }

  void _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.forestGreen,
            onPrimary: AppColors.onPrimary,
            onSurface: AppColors.parcelsTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) setState(() => _selectedDate = date);
  }

  void _save() {
    if (!_isValid) return;

    final cultivo = _catalog[_selectedCropIndex];
    final areaRaw = Hectareas(_areaController.text.trim()).value;
    final unidad = _selectedUnit == 'Hectáreas' ? 'ha' : 'm2';

    final terrenoTipo = _selectedTerrenoIndex >= 0
        ? _terrenoOptions[_selectedTerrenoIndex]
        : null;
    final suelo = _selectedSueloConditions
        .map((i) => _sueloOptions[i])
        .toList();
    final maleza = _selectedMalezaTypes.map((i) => _malezaOptions[i]).toList();

    context.read<ParcelBloc>().add(
      ParcelAddRequested(
        params: AddParcelParams(
          cultivoId: cultivo.id,
          cultivoNombre: cultivo.nombre,
          nombreParcela: _nameController.text.trim(),
          areaHa: areaRaw,
          unidadArea: unidad,
          region: _regionController.text.trim(),
          fechaSiembra: _selectedDate!,
          terrenoTipo: terrenoTipo,
          sueloCondiciones: suelo.isNotEmpty ? suelo : null,
          malezaTipos: maleza.isNotEmpty ? maleza : null,
        ),
      ),
    );
  }

  void _showSuccessOverlay(String cropName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SuccessOverlay(
        cropName: cropName,
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
    return BlocListener<ParcelBloc, ParcelState>(
      listener: (context, state) {
        if (state is ParcelSaved) {
          _showSuccessOverlay(state.parcel.cropName);
        }
        if (state is ParcelFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.burntOrange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<ParcelBloc, ParcelState>(
        builder: (context, state) {
          final isSaving = state is ParcelSaving;
          return Scaffold(
            backgroundColor: AppColors.parcelsBg,
            appBar: AppBar(
              backgroundColor: AppColors.forestGreen,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_outlined,
                  color: AppColors.onPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Nueva Parcela / Cultivo',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.onPrimary,
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
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 16),
                          child: Text(
                            'Completa solo la información que conozcas. Puedes editarla después.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.parcelsTextSecondary,
                            ),
                          ),
                        ),

                        // ── Campos obligatorios ──────────────────────────────
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Nombre de la parcela'),
                              const SizedBox(height: AppSpacing.xs),
                              _buildInput(
                                controller: _nameController,
                                hint: 'Ej. Milpa Norte',
                                icon: Icons.pin_drop_outlined,
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              _buildFieldLabel('Superficie'),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 65,
                                    child: _buildInput(
                                      controller: _areaController,
                                      hint: 'Ej. 2.5',
                                      icon: Icons.straighten_outlined,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    flex: 35,
                                    child: _buildUnitDropdown(),
                                  ),
                                ],
                              ),
                              if (_areaController.text.isNotEmpty &&
                                  _areaError != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  _areaError!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppColors.burntOrange,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xl),

                              _buildFieldLabel('Región / Comunidad'),
                              const SizedBox(height: AppSpacing.xs),
                              _buildInput(
                                controller: _regionController,
                                hint: 'Ej. Tuxtla Gutiérrez, Chiapas',
                                icon: Icons.place_outlined,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Escribe tu comunidad o región para mejorar recomendaciones agrícolas.',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.parcelsBorderLight,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              _buildFieldLabel('Cultivo principal'),
                              const SizedBox(height: AppSpacing.md),
                              _buildCropGrid(),
                              const SizedBox(height: AppSpacing.xl),

                              _buildFieldLabel('Fecha de siembra'),
                              const SizedBox(height: AppSpacing.xs),
                              _buildDatePicker(),
                              if (_selectedDate != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                _buildStagePill(
                                  _estimatePhenologicalStage(_selectedDate!),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // ── Información adicional (acordeón) ────────────────
                        _buildCard(
                          child: Column(
                            children: [
                              _buildAccordionHeader(),
                              if (_isAdditionalExpanded) ...[
                                const Divider(height: 1, thickness: 0.5),
                                Padding(
                                  padding: const EdgeInsets.all(AppSpacing.xxl),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildOptionalHeader(
                                        title: 'Tipo de terreno',
                                        subtitle:
                                            'Ayuda a interpretar el comportamiento del cultivo.',
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      _buildSingleSelector(
                                        items: _terrenoOptions,
                                        selectedIndex: _selectedTerrenoIndex,
                                        onSelected: (i) => setState(
                                          () => _selectedTerrenoIndex = i,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xxlPlus),
                                      _buildOptionalHeader(
                                        title: 'Condición del suelo',
                                        subtitle:
                                            'La IA usará esto para recomendar cultivos compatibles.',
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      _buildMultiSelector(
                                        items: _sueloOptions,
                                        selectedIndices:
                                            _selectedSueloConditions,
                                        onTap: (i) => setState(() {
                                          _selectedSueloConditions.contains(i)
                                              ? _selectedSueloConditions.remove(
                                                  i,
                                                )
                                              : _selectedSueloConditions.add(i);
                                        }),
                                      ),
                                      const SizedBox(height: AppSpacing.xxlPlus),
                                      _buildOptionalHeader(
                                        title: 'Malezas predominantes',
                                        subtitle:
                                            'Ayuda a mejorar la inferencia agronómica.',
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      _buildMultiSelector(
                                        items: _malezaOptions,
                                        selectedIndices: _selectedMalezaTypes,
                                        onTap: (i) => setState(() {
                                          _selectedMalezaTypes.contains(i)
                                              ? _selectedMalezaTypes.remove(i)
                                              : _selectedMalezaTypes.add(i);
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.parcelsChipGreenBg,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.forestGreen,
                                size: 16,
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Agregar información del terreno puede ayudar a generar recomendaciones más precisas.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.parcelsChipGreenText,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (!_isConnected) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.parcelsMutedBg,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.wifi_off_outlined,
                                  color: AppColors.parcelsBorderLight,
                                  size: 16,
                                ),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Sin conexión · necesitas estar en línea para registrar tu parcela',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.parcelsBorderLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.behemoth),
                      ],
                    ),
                  ),
                ),

                // ── CTA fijo ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xxlPlus),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.parcelsBorderLight.withValues(alpha: 0.3),
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
                        onPressed: (_isValid && !isSaving) ? _save : null,
                        icon: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onPrimary,
                                ),
                              )
                            : const Icon(Icons.check_outlined, size: 18),
                        label: Text(
                          isSaving ? 'Guardando...' : 'Guardar parcela',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warmAmber,
                          foregroundColor: AppColors.onWarmAmber,
                          disabledBackgroundColor: AppColors.parcelsTrackGrey,
                          disabledForegroundColor: AppColors.parcelsBorderLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lgXl),
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
        },
      ),
    );
  }

  // ── Builders ────────────────────────────────────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.parcelsBorderLight.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: child,
    );
  }

  Widget _buildAccordionHeader() {
    return GestureDetector(
      onTap: () =>
          setState(() => _isAdditionalExpanded = !_isAdditionalExpanded),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Información adicional (opcional)',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.parcelsTextPrimary,
              ),
            ),
            Icon(
              _isAdditionalExpanded
                  ? Icons.keyboard_arrow_up_outlined
                  : Icons.keyboard_arrow_down_outlined,
              color: AppColors.parcelsTextPrimary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitDropdown() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.mdLg),
        border: Border.all(
          color: AppColors.parcelsBorderLight.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedUnit,
          isExpanded: true,
          style: GoogleFonts.inter(color: AppColors.parcelsTextPrimary, fontSize: 13),
          items: [
            'Hectáreas',
            'm²',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedUnit = v);
          },
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.mdLg),
          border: Border.all(
            color: AppColors.parcelsBorderLight.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.parcelsTextSecondary,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(
              _selectedDate != null
                  ? '${_selectedDate!.day.toString().padLeft(2, '0')} / '
                        '${_selectedDate!.month.toString().padLeft(2, '0')} / '
                        '${_selectedDate!.year}'
                  : 'DD / MM / AAAA',
              style: GoogleFonts.inter(
                color: _selectedDate != null ? AppColors.parcelsTextPrimary : AppColors.parcelsBorderLight,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStagePill(String stage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.parcelsChipGreenBg,
        borderRadius: BorderRadius.circular(AppRadius.mdLg),
      ),
      child: Text(
        'Etapa estimada: $stage',
        style: GoogleFonts.inter(
          fontSize: 10,
          color: AppColors.parcelsChipGreenText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.parcelsTextSecondary,
      ),
    );
  }

  Widget _buildOptionalHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.parcelsTextPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.parcelsBorderLight),
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
        style: GoogleFonts.inter(color: AppColors.parcelsTextPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppColors.parcelsBorderLight, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.parcelsTextSecondary, size: 16),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xxl,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.mdLg),
            borderSide: BorderSide(
              color: AppColors.parcelsBorderLight.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.mdLg),
            borderSide: BorderSide(
              color: AppColors.parcelsBorderLight.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.mdLg),
            borderSide: const BorderSide(color: AppColors.forestGreen, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildCropGrid() {
    if (_catalogLoading) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.forestGreen),
        ),
      );
    }
    if (_catalog.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.parcelsSubtleBg,
          borderRadius: BorderRadius.circular(AppRadius.mdLg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'No se pudo cargar el catálogo de cultivos.',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.parcelsBorderLight),
              ),
            ),
            GestureDetector(
              onTap: _loadCatalog,
              child: Text(
                'Reintentar',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forestGreen,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.15,
      ),
      itemCount: _catalog.length,
      itemBuilder: (context, i) {
        final isSelected = i == _selectedCropIndex;
        final cultivo = _catalog[i];
        final emoji = _emojiMap[cultivo.nombre] ?? '🌿';
        return GestureDetector(
          onTap: () => setState(() => _selectedCropIndex = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.parcelsChipGreenBg
                  : AppColors.parcelsSubtleBg,
              borderRadius: BorderRadius.circular(AppRadius.lgXl),
              border: Border.all(
                color: isSelected
                    ? AppColors.forestGreen
                    : AppColors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: AppSpacing.xsPlus),
                Text(
                  cultivo.nombre,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.forestGreen
                        : AppColors.parcelsUnselectedText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleSelector({
    required List<String> items,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(items.length, (i) {
        final isSelected = i == selectedIndex;
        return GestureDetector(
          onTap: () => onSelected(i),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.parcelsChipGreenBg
                  : AppColors.parcelsMutedBg,
              borderRadius: BorderRadius.circular(AppRadius.mdLg),
              border: isSelected
                  ? Border.all(color: AppColors.forestGreen, width: 0.5)
                  : null,
            ),
            child: Text(
              items[i],
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppColors.forestGreen
                    : AppColors.parcelsUnselectedText,
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
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(items.length, (i) {
        final isSelected = selectedIndices.contains(i);
        return GestureDetector(
          onTap: () => onTap(i),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.parcelsChipGreenBg
                  : AppColors.parcelsMutedBg,
              borderRadius: BorderRadius.circular(AppRadius.mdLg),
              border: isSelected
                  ? Border.all(color: AppColors.forestGreen, width: 0.5)
                  : null,
            ),
            child: Text(
              items[i],
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppColors.forestGreen
                    : AppColors.parcelsUnselectedText,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// Overlay de éxito post-guardado — sin cambios visuales
// =============================================================================

class _SuccessOverlay extends StatelessWidget {
  final String cropName;
  final VoidCallback onDiagnosis;
  final VoidCallback onViewParcels;

  const _SuccessOverlay({
    required this.cropName,
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.giant),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.onPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.forestGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppSpacing.huge),
                Text(
                  '¡Parcela registrada!',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Tu cultivo de $cropName ha sido guardado. Puedes realizar tu primer diagnóstico cuando lo necesites.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onPrimary.withValues(alpha: 0.75),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.giant),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onDiagnosis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warmAmber,
                      foregroundColor: AppColors.onWarmAmber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lgXl),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Ir a diagnóstico →',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onViewParcels,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onPrimary,
                      side: const BorderSide(color: AppColors.onPrimary, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lgXl),
                      ),
                    ),
                    child: Text(
                      'Ver mis parcelas',
                      style: GoogleFonts.inter(
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
