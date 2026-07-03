import 'package:flutter/material.dart';

import '../../features/aprendiz/presentation/pages/aprendiz_agenda_page.dart';
import '../../features/aprendiz/presentation/pages/aprendiz_crop_register_page.dart';
import '../../features/aprendiz/presentation/pages/aprendiz_crop_route_page.dart';
import '../../features/aprendiz/presentation/pages/aprendiz_my_crop_page.dart';
import '../../features/aprendiz/presentation/pages/crop_history_page.dart';

abstract final class AppRoutes {
  AppRoutes._();

  static const String aprendizHome = '/aprendiz/home';
  static const String aprendizDiagnosis = '/aprendiz/diagnosis';
  static const String aprendizCropStatus = '/aprendiz/crop-status';
  static const String aprendizCropRoute = '/aprendiz/crop-route';
  static const String aprendizAgenda = '/aprendiz/agenda';
  static const String aprendizProfile = '/aprendiz/profile';
  static const String aprendizCropHistory = '/aprendiz/crop-history';
  static const String aprendizCropRegister = '/aprendiz/crop-register';
  static const String aprendizDiagnosisResult = '/aprendiz/diagnosis-result';

  static void goCropStatus(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AprendizMyCropPage()),
      );

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
