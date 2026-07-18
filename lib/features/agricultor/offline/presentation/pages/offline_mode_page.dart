import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../offline_knowledge/presentation/cubit/offline_package_manager_cubit.dart';
import '../cubit/offline_cubit.dart';
import '../widgets/offline_error_body.dart';
import '../widgets/offline_loaded_body.dart';
import '../widgets/offline_loading_body.dart';

// =============================================================================
// PAGE
// =============================================================================

class OfflineModePage extends StatefulWidget {
  const OfflineModePage({super.key});

  @override
  State<OfflineModePage> createState() => _OfflineModePageState();
}

class _OfflineModePageState extends State<OfflineModePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OfflineCubit>().loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OfflinePackageManagerCubit>()..loadStatuses(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Diagnóstico sin Conexión',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: AppColors.onPrimary)),
              Text('Descarga paquetes de diagnóstico para usar sin internet',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white70)),
            ],
          ),
        ),
        body: BlocBuilder<OfflineCubit, OfflineState>(
          builder: (context, state) => switch (state) {
            OfflineInitial() || OfflineLoading() => const OfflineLoadingBody(),
            OfflineError(:final message) => OfflineErrorBody(
                message: message,
                onRetry: () => context.read<OfflineCubit>().loadStatus(),
              ),
            OfflineLoaded() => OfflineLoadedBody(state: state),
          },
        ),
      ),
    );
  }
}
