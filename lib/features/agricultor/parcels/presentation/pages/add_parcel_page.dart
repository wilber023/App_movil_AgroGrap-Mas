import 'dart:async';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../../core/constants/supported_crops.dart';
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
import '../widgets/parcel_accordion_header.dart';
import '../widgets/parcel_choice_chips_row.dart';
import '../widgets/parcel_crop_grid.dart';
import '../widgets/parcel_form_pieces.dart';
import '../widgets/parcel_success_overlay.dart';

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
              .where((c) => SupportedCrops.names.contains(c.nombre))
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
      builder: (ctx) => ParcelSuccessOverlay(
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
                        ParcelFormCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const ParcelFieldLabel('Nombre de la parcela'),
                              const SizedBox(height: AppSpacing.xs),
                              ParcelTextInput(
                                controller: _nameController,
                                hint: 'Ej. Milpa Norte',
                                icon: Icons.pin_drop_outlined,
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              const ParcelFieldLabel('Superficie'),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 65,
                                    child: ParcelTextInput(
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
                                    child: ParcelUnitDropdown(
                                      value: _selectedUnit,
                                      onChanged: (v) => setState(() => _selectedUnit = v),
                                    ),
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

                              const ParcelFieldLabel('Región / Comunidad'),
                              const SizedBox(height: AppSpacing.xs),
                              ParcelTextInput(
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

                              const ParcelFieldLabel('Cultivo principal'),
                              const SizedBox(height: AppSpacing.md),
                              ParcelCropGrid(
                                catalogLoading: _catalogLoading,
                                catalog: _catalog,
                                selectedIndex: _selectedCropIndex,
                                emojiFor: SupportedCrops.emojiFor,
                                onSelected: (i) => setState(() => _selectedCropIndex = i),
                                onRetry: _loadCatalog,
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              const ParcelFieldLabel('Fecha de siembra'),
                              const SizedBox(height: AppSpacing.xs),
                              ParcelDatePickerField(
                                selectedDate: _selectedDate,
                                onTap: _pickDate,
                              ),
                              if (_selectedDate != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                ParcelStagePill(
                                  _estimatePhenologicalStage(_selectedDate!),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // ── Información adicional (acordeón) ────────────────
                        ParcelFormCard(
                          child: Column(
                            children: [
                              ParcelAccordionHeader(
                                expanded: _isAdditionalExpanded,
                                onTap: () => setState(
                                  () => _isAdditionalExpanded = !_isAdditionalExpanded,
                                ),
                              ),
                              if (_isAdditionalExpanded) ...[
                                const Divider(height: 1, thickness: 0.5),
                                Padding(
                                  padding: const EdgeInsets.all(AppSpacing.xxl),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const ParcelOptionalHeader(
                                        title: 'Tipo de terreno',
                                        subtitle:
                                            'Ayuda a interpretar el comportamiento del cultivo.',
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      ParcelChoiceChipsRow(
                                        items: _terrenoOptions,
                                        isSelected: (i) => i == _selectedTerrenoIndex,
                                        onItemTap: (i) => setState(
                                          () => _selectedTerrenoIndex = i,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xxlPlus),
                                      const ParcelOptionalHeader(
                                        title: 'Condición del suelo',
                                        subtitle:
                                            'La IA usará esto para recomendar cultivos compatibles.',
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      ParcelChoiceChipsRow(
                                        items: _sueloOptions,
                                        isSelected: (i) => _selectedSueloConditions.contains(i),
                                        onItemTap: (i) => setState(() {
                                          _selectedSueloConditions.contains(i)
                                              ? _selectedSueloConditions.remove(
                                                  i,
                                                )
                                              : _selectedSueloConditions.add(i);
                                        }),
                                      ),
                                      const SizedBox(height: AppSpacing.xxlPlus),
                                      const ParcelOptionalHeader(
                                        title: 'Malezas predominantes',
                                        subtitle:
                                            'Ayuda a mejorar la inferencia agronómica.',
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      ParcelChoiceChipsRow(
                                        items: _malezaOptions,
                                        isSelected: (i) => _selectedMalezaTypes.contains(i),
                                        onItemTap: (i) => setState(() {
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
}
