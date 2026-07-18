import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/crop_practice_location.dart';
import '../bloc/cultivo_bloc.dart';
import '../widgets/cultivo_date_field.dart';
import '../widgets/cultivo_form_section_label.dart';
import '../widgets/cultivo_harvest_estimate_chip.dart';
import '../widgets/cultivo_register_header.dart';
import '../widgets/cultivo_register_submit_button.dart';
import '../widgets/cultivo_selectable_grid_card.dart';
import 'aprendiz_crop_route_page.dart';

class AprendizCropRegisterPage extends StatelessWidget {
  const AprendizCropRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CultivoBloc>(),
      child: const _AprendizCropRegisterView(),
    );
  }
}

class _AprendizCropRegisterView extends StatefulWidget {
  const _AprendizCropRegisterView();

  @override
  State<_AprendizCropRegisterView> createState() => _AprendizCropRegisterViewState();
}

class _AprendizCropRegisterViewState extends State<_AprendizCropRegisterView> {
  int? _selectedCropIndex;
  DateTime? _sowingDate;
  CropPracticeLocation? _selectedPracticeLocation;

  static const _crops = [
    ('🍈', 'Calabaza'),
    ('🫘', 'Frijol'),
    ('🌽', 'Maíz'),
    ('🥔', 'Papa'),
    ('🍅', 'Tomate'),
  ];

  static const _practiceLocations = [
    (CropPracticeLocation.home, Icons.cottage_outlined, 'Jardín en casa'),
    (CropPracticeLocation.greenhouse, Icons.warehouse_outlined, 'Invernadero'),
  ];

  bool get _canSubmit =>
      _selectedCropIndex != null && _sowingDate != null && _selectedPracticeLocation != null;

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
            onPrimary: AppColors.aOnPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _sowingDate = date);
  }

  DateTime? get _estimatedHarvest => _sowingDate?.add(const Duration(days: 18 * 7));

  void _submit() {
    if (!_canSubmit) return;
    final cropName = _crops[_selectedCropIndex!].$2;
    context.read<CultivoBloc>().add(
          CultivoCropRegistered(
            cropName: cropName,
            startDate: _sowingDate!,
            practiceLocation: _selectedPracticeLocation!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CultivoBloc, CultivoState>(
      listener: (context, state) {
        if (state is CultivoLoaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Cultivo registrado! Generando plan para ${state.plan.cropName}...'),
              backgroundColor: AppColors.aSecondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.mdLg)),
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AprendizCropRoutePage()),
          );
        } else if (state is CultivoFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.mdLg)),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.aMint,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const CultivoRegisterHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxlPlus,
                    AppSpacing.xxlPlus,
                    AppSpacing.xxlPlus,
                    AppSpacing.titan,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CultivoFormSectionLabel(label: '¿Qué vas a sembrar?'),
                      const SizedBox(height: AppSpacing.xl),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: AppSpacing.lg,
                          crossAxisSpacing: AppSpacing.lg,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _crops.length,
                        itemBuilder: (context, i) {
                          final (emoji, name) = _crops[i];
                          return CultivoSelectableGridCard(
                            icon: Text(emoji, style: const TextStyle(fontSize: 26)),
                            label: name,
                            isSelected: _selectedCropIndex == i,
                            onTap: () => setState(() => _selectedCropIndex = i),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xhuge),

                      const CultivoFormSectionLabel(label: 'Fecha de siembra'),
                      const SizedBox(height: AppSpacing.xl),
                      CultivoDateField(
                        selectedDate: _sowingDate,
                        formatDate: _formatDate,
                        onTap: _pickDate,
                      ),
                      if (_estimatedHarvest != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        CultivoHarvestEstimateChip(
                          formattedDate: _formatDate(_estimatedHarvest!),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xhuge),

                      const CultivoFormSectionLabel(label: '¿Dónde vas a practicar?'),
                      const SizedBox(height: AppSpacing.xl),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.lg,
                          crossAxisSpacing: AppSpacing.lg,
                          childAspectRatio: 1.3,
                        ),
                        itemCount: _practiceLocations.length,
                        itemBuilder: (context, i) {
                          final (location, iconData, label) = _practiceLocations[i];
                          final isSelected = _selectedPracticeLocation == location;
                          return CultivoSelectableGridCard(
                            icon: Icon(
                              iconData,
                              size: 28,
                              color: isSelected ? AppColors.aSecondary : AppColors.aOnSurfaceVariant,
                            ),
                            label: label,
                            isSelected: isSelected,
                            onTap: () => setState(() => _selectedPracticeLocation = location),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xxlPlus,
            AppSpacing.xl,
            AppSpacing.xxlPlus,
            MediaQuery.of(context).viewPadding.bottom + AppSpacing.xxlPlus,
          ),
          color: AppColors.aMint,
          child: CultivoRegisterSubmitButton(canSubmit: _canSubmit, onPressed: _submit),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
