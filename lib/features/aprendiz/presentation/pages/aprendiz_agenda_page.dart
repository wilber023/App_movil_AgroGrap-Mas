import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/crop_activity_entity.dart';
import '../bloc/aprendiz_my_crop_cubit.dart';

final _mockActivities = [
  CropActivityEntity(
    id: 'a1',
    title: 'Primera aplicación de fungicida',
    description: 'Maíz · Milpa Norte',
    weekNumber: 6,
    status: ActivityStatus.pending,
    scheduledDate: DateTime.now(),
  ),
  CropActivityEntity(
    id: 'a2',
    title: 'Seguimiento y revisión',
    description: 'Verificar respuesta al tratamiento.',
    weekNumber: 7,
    status: ActivityStatus.pending,
    scheduledDate: DateTime.now().add(const Duration(days: 7)),
  ),
  CropActivityEntity(
    id: 'a3',
    title: 'Nueva inspección con foto',
    description: 'Inspección fotográfica programada.',
    weekNumber: 8,
    status: ActivityStatus.pending,
    scheduledDate: DateTime.now().add(const Duration(days: 14)),
  ),
];

class AprendizAgendaPage extends StatelessWidget {
  const AprendizAgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AprendizMyCropCubit>()..loadPlan(),
      child: const _AgendaView(),
    );
  }
}

class _AgendaView extends StatefulWidget {
  const _AgendaView();

  @override
  State<_AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends State<_AgendaView> {
  DateTime _selectedDay = DateTime.now();
  DateTime _currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aMint,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(),
            Expanded(
              child: BlocBuilder<AprendizMyCropCubit, AprendizMyCropState>(
                builder: (context, state) {
                  if (state is AprendizMyCropLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.aSecondary));
                  }

                  final activities = state is AprendizMyCropLoaded
                      ? state.plan.activities
                      : _mockActivities;

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                          child: Text(
                            'Mi Agenda',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.aPrimary,
                            ),
                          ),
                        ),

                        _CalendarStrip(
                          selectedDay: _selectedDay,
                          currentMonth: _currentMonth,
                          activities: activities,
                          onDaySelected: (d) => setState(() => _selectedDay = d),
                          onPrevMonth: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)),
                          onNextMonth: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1)),
                        ),

                        const SizedBox(height: 16),
                        _TodaySection(activities: activities, selectedDay: _selectedDay),
                        const SizedBox(height: 16),
                        _UpcomingSection(activities: activities, selectedDay: _selectedDay),
                        const SizedBox(height: 80),
                      ],
                    ),
                  );
                },
              ),
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

class _CalendarStrip extends StatelessWidget {
  final DateTime selectedDay;
  final DateTime currentMonth;
  final List<CropActivityEntity> activities;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const _CalendarStrip({
    required this.selectedDay,
    required this.currentMonth,
    required this.activities,
    required this.onDaySelected,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  static const _monthNames = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];
  static const _dayNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  bool _hasActivity(DateTime day) {
    return activities.any((a) =>
        a.scheduledDate.year == day.year &&
        a.scheduledDate.month == day.month &&
        a.scheduledDate.day == day.day);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Show 7 days centered around today
    final days = List.generate(7, (i) {
      final offset = i - (now.weekday - 1);
      return DateTime(now.year, now.month, now.day + offset);
    });

    return Container(
      color: AppColors.aSurfaceContainerLowest,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          // Month navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.aOnSurfaceVariant, size: 20),
                onPressed: onPrevMonth,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                '${_monthNames[currentMonth.month - 1]} ${currentMonth.year}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.aOnSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.aOnSurfaceVariant, size: 20),
                onPressed: onNextMonth,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: days.asMap().entries.map((entry) {
                final day = entry.value;
                final dayIndex = (day.weekday - 1) % 7;
                final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
                final isSelected = day.year == selectedDay.year && day.month == selectedDay.month && day.day == selectedDay.day;
                final hasAct = _hasActivity(day);

                return GestureDetector(
                  onTap: () => onDaySelected(day),
                  child: SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        Text(
                          _dayNames[dayIndex],
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.aOnSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.aPrimaryContainer
                                : isToday
                                    ? AppColors.aMint
                                    : Colors.transparent,
                            border: isToday && !isSelected
                                ? Border.all(color: AppColors.aSecondary, width: 1.5)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                        ? AppColors.aSecondary
                                        : AppColors.aOnSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasAct ? AppColors.aOrange : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySection extends StatelessWidget {
  final List<CropActivityEntity> activities;
  final DateTime selectedDay;

  const _TodaySection({required this.activities, required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    final todayActivities = activities.where((a) {
      return a.status == ActivityStatus.pending &&
          a.scheduledDate.year == selectedDay.year &&
          a.scheduledDate.month == selectedDay.month &&
          a.scheduledDate.day == selectedDay.day;
    }).toList();

    const monthNames = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOY · ${selectedDay.day} ${monthNames[selectedDay.month - 1].toUpperCase()}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.aOnSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
            ),
          ),
          const SizedBox(height: 10),
          if (todayActivities.isEmpty)
            Container(
              decoration: BoxDecoration(
                color: AppColors.aSurfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.aSecondary, size: 20),
                  SizedBox(width: 12),
                  Text('Sin actividades para hoy 🎉', style: TextStyle(fontSize: 14, color: AppColors.aOnSurfaceVariant)),
                ],
              ),
            )
          else
            ...todayActivities.map((a) => _UrgentActivityCard(activity: a)),
        ],
      ),
    );
  }
}

class _UrgentActivityCard extends StatefulWidget {
  final CropActivityEntity activity;
  const _UrgentActivityCard({required this.activity});

  @override
  State<_UrgentActivityCard> createState() => _UrgentActivityCardState();
}

class _UrgentActivityCardState extends State<_UrgentActivityCard> {
  bool _marked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _marked ? AppColors.aMint : AppColors.aSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: _marked ? AppColors.aSecondary : AppColors.error,
            width: 4,
          ),
          top: BorderSide(color: AppColors.aOutlineVariant),
          right: BorderSide(color: AppColors.aOutlineVariant),
          bottom: BorderSide(color: AppColors.aOutlineVariant),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: _marked ? AppColors.aSecondaryContainer : AppColors.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _marked ? Icons.check : Icons.priority_high,
                  color: _marked ? AppColors.aSecondary : AppColors.error,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.activity.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _marked ? AppColors.aSecondary : AppColors.aOnSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Text(
              widget.activity.description,
              style: const TextStyle(fontSize: 13, color: AppColors.aOnSurfaceVariant),
            ),
          ),
          const SizedBox(height: 12),
          if (!_marked)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => _marked = true),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Marcar completada',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle, color: AppColors.aSecondary, size: 18),
                SizedBox(width: 6),
                Text(
                  'Completada',
                  style: TextStyle(color: AppColors.aSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _UpcomingSection extends StatelessWidget {
  final List<CropActivityEntity> activities;
  final DateTime selectedDay;

  const _UpcomingSection({required this.activities, required this.selectedDay});

  static const _dotColors = [
    AppColors.aOrange,
    AppColors.aSecondary,
    AppColors.aOrangeAccent,
  ];

  @override
  Widget build(BuildContext context) {
    final upcoming = activities.where((a) {
      return a.status == ActivityStatus.pending &&
          a.scheduledDate.isAfter(selectedDay.add(const Duration(days: 0))) &&
          !(a.scheduledDate.year == selectedDay.year &&
            a.scheduledDate.month == selectedDay.month &&
            a.scheduledDate.day == selectedDay.day);
    }).take(5).toList();

    if (upcoming.isEmpty) return const SizedBox.shrink();

    const monthShort = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRÓXIMOS',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.aOnSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
            ),
          ),
          const SizedBox(height: 10),
          ...upcoming.asMap().entries.map((entry) {
            final i = entry.key;
            final a = entry.value;
            final dotColor = _dotColors[i % _dotColors.length];
            final dateStr = '${a.scheduledDate.day} ${monthShort[a.scheduledDate.month - 1]}';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.aSurfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.aOutlineVariant),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '$dateStr · ${a.title}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.aOnSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
