import 'package:flutter/material.dart';

import '../../features/aprendiz/agenda/agenda.dart';
import '../../features/aprendiz/cultivo/cultivo.dart';
import '../../features/aprendiz/presentation/pages/crop_history_page.dart';

abstract final class AppRoutes {
  AppRoutes._();

  static const String aprendizHome = '/aprendiz/home';
  static const String aprendizDiagnosis = '/aprendiz/diagnosis';
  static const String aprendizCropRoute = '/aprendiz/crop-route';
  static const String aprendizAgenda = '/aprendiz/agenda';
  static const String aprendizProfile = '/aprendiz/profile';
  static const String aprendizCropHistory = '/aprendiz/crop-history';
  static const String aprendizCropRegister = '/aprendiz/crop-register';
  static const String aprendizDiagnosisResult = '/aprendiz/diagnosis-result';

  static void goCropRoute(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AprendizCropRoutePage()),
      );

  static void goAgenda(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AprendizAgendaPage()),
      );

  static void goCropHistory(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CropHistoryPage()),
      );

  static void goCropRegister(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AprendizCropRegisterPage()),
      );

}
