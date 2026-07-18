import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../cultivo/domain/entities/crop_activity_entity.dart';
import '../bloc/aprendiz_home_bloc.dart';
import '../widgets/home_content.dart';
import '../widgets/home_error_view.dart';
import '../widgets/home_header.dart';
import '../widgets/home_loading_view.dart';
import '../widgets/inspection_bottom_sheet.dart';

class AprendizHomePage extends StatelessWidget {
  const AprendizHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AprendizHomeBloc>()..add(const HomeOverviewRequested()),
      child: const _AprendizHomeView(),
    );
  }
}

class _AprendizHomeView extends StatelessWidget {
  const _AprendizHomeView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AprendizHomeBloc, AprendizHomeState>(
      listenWhen: (previous, current) =>
          current is HomeLoaded && current.dueInspection != null && !current.modalAlreadyShown,
      listener: (context, state) {
        if (state is HomeLoaded && state.dueInspection != null && !state.modalAlreadyShown) {
          context.read<AprendizHomeBloc>().add(const DueInspectionModalShown());
          _showInspectionModal(context, state.dueInspection!);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.aMint,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<AprendizHomeBloc, AprendizHomeState>(
            builder: (context, state) {
              final userName = state is HomeLoaded ? state.overview.userName : '';
              final hasNotices = state is HomeLoaded && state.overview.notices.isNotEmpty;

              return Column(
                children: [
                  HomeHeader(userName: userName, hasNotices: hasNotices),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (state is HomeFailure) {
                          return HomeErrorView(
                            message: state.message,
                            onRetry: () =>
                                context.read<AprendizHomeBloc>().add(const HomeOverviewRequested()),
                          );
                        }
                        if (state is HomeLoaded) {
                          return RefreshIndicator(
                            color: AppColors.aSecondary,
                            onRefresh: () async =>
                                context.read<AprendizHomeBloc>().add(const HomeOverviewRequested()),
                            child: HomeContent(state: state),
                          );
                        }
                        return const HomeLoadingView();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showInspectionModal(BuildContext context, CropActivityEntity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => InspectionBottomSheet(
        activity: activity,
        onPostpone: () => context.read<AprendizHomeBloc>().add(InspectionPostponed(activity.id)),
      ),
    );
  }
}
