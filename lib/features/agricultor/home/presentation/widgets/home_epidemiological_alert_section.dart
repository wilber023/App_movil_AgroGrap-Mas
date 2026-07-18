import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../clustering/presentation/cubit/epidemiological_alert_cubit.dart';
import '../../../../clustering/presentation/widgets/epidemiological_alert_banner.dart';

/// Alerta epidemiológica regional de HomePage — dato real de
/// GET /api/v1/alertas (clustering SENASICA), filtrado por el estado que el
/// usuario configuró en Ajustes > Notificaciones (o alerta nacional si no
/// configuró ninguno). Independiente de HomeBloc: una sola carga al entrar
/// a Inicio, sin polling.
class HomeEpidemiologicalAlertSection extends StatelessWidget {
  const HomeEpidemiologicalAlertSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EpidemiologicalAlertCubit>()..load(),
      child: BlocBuilder<EpidemiologicalAlertCubit, EpidemiologicalAlertState>(
        builder: (context, state) {
          final alerta = state is EpidemiologicalAlertLoaded ? state.alerta : null;
          return EpidemiologicalAlertBanner(alerta: alerta);
        },
      ),
    );
  }
}
