import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'aprendiz_home_page.dart';
import 'aprendiz_my_crop_page.dart';
import 'diagnosis_entry_aprendiz_page.dart';
import 'aprendiz_agenda_page.dart';
import 'aprendiz_profile_page.dart';

class AprendizMainShell extends StatefulWidget {
  const AprendizMainShell({super.key});

  @override
  State<AprendizMainShell> createState() => _AprendizMainShellState();
}

class _AprendizMainShellState extends State<AprendizMainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AprendizHomePage(),
    DiagnosisEntryAprendizPage(),
    AprendizMyCropPage(),
    AprendizAgendaPage(),
    AprendizProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.forestGreen,
        unselectedItemColor: AppColors.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt_rounded),
            label: 'Diagnóstico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco_outlined),
            activeIcon: Icon(Icons.eco_rounded),
            label: 'Mi Cultivo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today_rounded),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
