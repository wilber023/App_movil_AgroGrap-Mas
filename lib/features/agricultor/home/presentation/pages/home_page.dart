import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../clustering/presentation/cubit/epidemiological_alert_cubit.dart';
import '../../../../clustering/presentation/widgets/epidemiological_alert_banner.dart';
import '../../../../login/auth/presentation/bloc/auth_bloc.dart';
import '../../../../login/auth/presentation/bloc/auth_state.dart';
import '../../../../notifications/presentation/pages/notifications_page.dart';
import '../../../../subscription/presentation/pages/subscription_page.dart';
import '../../../diagnosis/presentation/pages/diagnosis_page.dart';
import '../../../parcels/domain/entities/parcel_entity.dart';
import '../../../parcels/presentation/bloc/parcel_bloc.dart';
import '../../../treatment/domain/entities/treatment_entity.dart';
import '../../../treatment/presentation/bloc/treatment_bloc.dart';
import '../bloc/home_bloc.dart';

// =============================================================================
// Helpers puramente de presentacion. No agregan ningun dato nuevo: solo
// formatean o clasifican visualmente datos que ya exponen HomeBloc,
// ParcelBloc y TreatmentBloc (los 3 ya provistos en main.dart, no se creo
// ningun Bloc/UseCase/Repository nuevo para esta pantalla).
// =============================================================================

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Buenos días';
  if (hour < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

String _firstName(String fullName) =>
    fullName.trim().isEmpty ? '' : fullName.trim().split(' ').first;

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays >= 1) {
    return 'hace ${diff.inDays} día${diff.inDays == 1 ? '' : 's'}';
  }
  if (diff.inHours >= 1) return 'hace ${diff.inHours} h';
  if (diff.inMinutes >= 1) return 'hace ${diff.inMinutes} min';
  return 'hace un momento';
}

/// Relabel puramente visual del status ya almacenado en ParcelEntity.status
/// ('Alerta' | 'Seguimiento' | 'Saludable' | 'Sin diagnostico'). No cambia
/// el dato guardado, solo como se muestra.
({String label, Color color}) _parcelStatusInfo(String status) {
  switch (status) {
    case 'Alerta':
      return (label: 'Riesgo alto', color: AppColors.error);
    case 'Seguimiento':
      return (label: 'Atención', color: AppColors.burntOrange);
    case 'Saludable':
      return (label: 'Saludable', color: AppColors.forestGreen);
    default:
      return (label: 'Sin diagnóstico', color: AppColors.onSurfaceVariant);
  }
}

/// No existe un porcentaje de salud medido en el dominio (ParcelEntity no
/// tiene ese campo). Este numero es una representacion visual estilizada
/// del status ya conocido, no una metrica precisa — por eso el anillo se
/// etiqueta "Estado del cultivo" y no "Salud medida".
int? _parcelStatusTier(String status) {
  switch (status) {
    case 'Saludable':
      return 92;
    case 'Seguimiento':
      return 60;
    case 'Alerta':
      return 30;
    default:
      return null; // Sin diagnostico: no se inventa un numero.
  }
}

IconData _cropIcon(String cropName) {
  final name = cropName.toLowerCase();
  if (name.contains('tomate')) return Icons.local_pizza_outlined;
  if (name.contains('papa')) return Icons.egg_outlined;
  if (name.contains('maíz') || name.contains('maiz')) return Icons.grass_outlined;
  if (name.contains('pepino')) return Icons.eco_outlined;
  if (name.contains('calabaza')) return Icons.circle_outlined;
  if (name.contains('pimiento') || name.contains('chile')) return Icons.local_fire_department_outlined;
  if (name.contains('fresa')) return Icons.favorite_border_rounded;
  return Icons.eco_outlined;
}

class HomePage extends StatelessWidget {
  /// Cambia de tab dentro del BottomNavigationBar (lo provee MainShell en
  /// main.dart). Si es null (ej. un test que monta HomePage aislada), los
  /// enlaces "Ver agenda"/"Ver todos" simplemente no hacen nada — no
  /// truena la pantalla.
  final ValueChanged<int>? onNavigateToTab;
  const HomePage({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxlPlus,
                  vertical: AppSpacing.xhuge,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPremiumBanner(context),
                    const SizedBox(height: AppSpacing.huge),
                    _buildCameraActionCard(context),
                    const SizedBox(height: AppSpacing.xhuge),
                    _buildTodaySummary(context),
                    const SizedBox(height: AppSpacing.xhuge),
                    _buildActiveCropsSection(context),
                    const SizedBox(height: AppSpacing.xhuge),
                    _buildEpidemiologicalAlertBanner(context),
                    const SizedBox(height: AppSpacing.xhuge),
                    _buildTodayTasksSection(context),
                    const SizedBox(height: AppSpacing.xhuge),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Encabezado
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => curr is AuthAuthenticated || curr is AuthUnauthenticated,
      builder: (context, authState) {
        final fullName = authState is AuthAuthenticated ? authState.user.fullName : '';
        final name = _firstName(fullName);

        return BlocBuilder<HomeBloc, HomeState>(
          builder: (context, homeState) {
            final dashboard = homeState is HomeLoaded ? homeState.dashboard : null;
            final hasUnread = dashboard?.recentAlerts.any((a) => !a.isRead) ?? false;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxlPlus,
                AppSpacing.xxl,
                AppSpacing.xxlPlus,
                AppSpacing.xxxl,
              ),
              color: AppColors.forestGreen,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name.isEmpty ? _greeting() : '${_greeting()}, $name 👋',
                          style: AppTypography.etiquetaSm.copyWith(
                            color: AppColors.onPrimary.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'AgroGraph IA',
                          style: AppTypography.tituloLg.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Tu asistente agrícola inteligente',
                          style: AppTypography.etiquetaSm.copyWith(
                            color: AppColors.onPrimary.withValues(alpha: 0.75),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  GestureDetector(
                    onTap: () => Navigator.push(context, NotificationsPage.route()),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.onPrimary,
                          size: 26,
                        ),
                        if (hasUnread)
                          Positioned(
                            right: -1,
                            top: -1,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.forestGreen, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Banner premium (sin cambios de logica, solo icono)
  // ---------------------------------------------------------------------------

  Widget _buildPremiumBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, SubscriptionPage.route()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          border: Border.all(
            color: AppColors.primaryContainer.withValues(alpha: 0.8),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.forestGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, color: AppColors.onPrimary, size: 14),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'Desbloquea diagnósticos ilimitados y alertas avanzadas. '),
                    TextSpan(
                      text: 'Mejorar a Pro →',
                      style: AppTypography.etiquetaSm.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tarjeta de escaneo
  // ---------------------------------------------------------------------------

  Widget _buildCameraActionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.huge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xhuge),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      // Row + Expanded (no Stack/Positioned): el texto/boton tiene prioridad
      // sobre el ancho disponible y la ilustracion (96px fijos) nunca puede
      // solaparse con ellos — si la pantalla es angosta, el titulo envuelve
      // a 2 lineas (la tarjeta crece) en vez de superponerse.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.onPrimary, size: 26),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  'Escanear cultivo',
                  style: AppTypography.tituloLg.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  // Etiqueta breve — reemplaza "Diagnóstico IA en segundos" a pedido.
                  'Detecta enfermedades al instante',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DiagnosisPage()),
                    ),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.primary),
                    label: Text(
                      'Tomar fotografía',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          const _ScanFrameIllustration(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Resumen de hoy — reutiliza TreatmentBloc (misma fuente que la Agenda)
  // ---------------------------------------------------------------------------

  Widget _buildTodaySummary(BuildContext context) {
    return BlocBuilder<TreatmentBloc, TreatmentState>(
      builder: (context, state) {
        final treatments = state is TreatmentAgendaLoaded ? state.treatments : const <TreatmentEntity>[];
        final overdue = treatments.where((t) => t.isOverdue).length;
        final today = treatments.where((t) => t.isDueToday).length;
        final week = treatments.where((t) => t.isDueThisWeek).length;
        final completed = treatments.where((t) => t.activeStep == null).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Resumen de hoy',
              action: 'Ver agenda',
              onTap: () => onNavigateToTab?.call(3),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _HomeStat(
                    count: overdue,
                    label: 'Vencidos',
                    color: AppColors.error,
                    icon: Icons.error_outline_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _HomeStat(
                    count: today,
                    label: 'Hoy',
                    color: AppColors.burntOrange,
                    icon: Icons.event_note_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _HomeStat(
                    count: week,
                    label: 'Esta semana',
                    color: AppColors.forestGreen,
                    icon: Icons.eco_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _HomeStat(
                    count: completed,
                    label: 'Completados',
                    color: AppColors.infoBlue,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Cultivos activos — tarjetas horizontales
  // ---------------------------------------------------------------------------

  Widget _buildActiveCropsSection(BuildContext context) {
    return BlocBuilder<ParcelBloc, ParcelState>(
      builder: (context, parcelState) {
        final parcels = parcelState is ParcelLoaded ? parcelState.parcels : const <ParcelEntity>[];
        final isLoading = parcelState is ParcelLoading || parcelState is ParcelInitial;
        final treatmentState = context.watch<TreatmentBloc>().state;
        final treatments = treatmentState is TreatmentAgendaLoaded
            ? treatmentState.treatments
            : const <TreatmentEntity>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Cultivos activos',
              action: parcels.isEmpty ? null : 'Ver todos',
              onTap: () => onNavigateToTab?.call(2),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (isLoading)
              const SizedBox(
                height: 80,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestGreen),
                  ),
                ),
              )
            else if (parcels.isEmpty)
              _buildEmptyParcels()
            else
              SizedBox(
                height: 176,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: parcels.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xl),
                  itemBuilder: (_, i) => _CropCard(
                    parcel: parcels[i],
                    treatments: treatments,
                    onTap: () => onNavigateToTab?.call(2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyParcels() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.homeEmptyIconBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_florist_outlined, color: AppColors.homeEmptyIconFg, size: 18),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aún no tienes parcelas',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Registra tu primer cultivo en la pestaña Mis Parcelas',
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Alerta epidemiológica regional — dato real de
  // GET /api/v1/alertas (clustering SENASICA), filtrado por el estado que el
  // usuario configuró en Ajustes > Notificaciones (o alerta nacional si no
  // configuró ninguno). Independiente de HomeBloc: una sola carga al entrar
  // a Inicio, sin polling.
  // ---------------------------------------------------------------------------

  Widget _buildEpidemiologicalAlertBanner(BuildContext context) {
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

  // ---------------------------------------------------------------------------
  // Tareas programadas — misma fuente que la Agenda. No se muestran horas
  // de reloj (10:00 AM, etc.) porque los tratamientos no tienen una hora
  // programada real, solo fecha — mostrarlas seria inventar un dato.
  // ---------------------------------------------------------------------------

  Widget _buildTodayTasksSection(BuildContext context) {
    return BlocBuilder<TreatmentBloc, TreatmentState>(
      builder: (context, state) {
        final treatments = state is TreatmentAgendaLoaded ? state.treatments : const <TreatmentEntity>[];
        final pending = treatments.where((t) => t.activeStep != null).toList()
          ..sort((a, b) {
            int rank(TreatmentEntity t) => t.isOverdue ? 0 : (t.isDueToday ? 1 : 2);
            final r = rank(a).compareTo(rank(b));
            if (r != 0) return r;
            return a.activeStep!.scheduledDate.compareTo(b.activeStep!.scheduledDate);
          });
        final display = pending.take(3).toList();

        if (display.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Tareas programadas',
              action: 'Ver todas',
              onTap: () => onNavigateToTab?.call(3),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.onPrimary,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5), width: 0.5),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < display.length; i++)
                    _TaskRow(
                      treatment: display[i],
                      isLast: i == display.length - 1,
                      onTap: () => onNavigateToTab?.call(3),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

}

// =============================================================================
// Widgets auxiliares
// =============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback onTap;
  const _SectionHeader({required this.title, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.labelMd.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action!,
                  style: AppTypography.etiquetaSm.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.forestGreen, size: 16),
              ],
            ),
          ),
      ],
    );
  }
}

class _HomeStat extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;
  const _HomeStat({required this.count, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$count',
            style: AppTypography.headlineMd.copyWith(color: color, fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.etiquetaSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CropCard extends StatelessWidget {
  final ParcelEntity parcel;
  final List<TreatmentEntity> treatments;
  final VoidCallback onTap;
  const _CropCard({required this.parcel, required this.treatments, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _parcelStatusInfo(parcel.status);
    final tier = _parcelStatusTier(parcel.status);

    // Mejor esfuerzo: no existe un vinculo real parcela<->tratamiento en el
    // dominio (TreatmentEntity solo guarda el nombre del cultivo, no un
    // parcelId), asi que se empareja por nombre de cultivo. Si el
    // agricultor tiene 2 parcelas del mismo cultivo, ambas mostrarian la
    // misma tarea — limitacion conocida, no se oculta.
    TreatmentEntity? match;
    for (final t in treatments) {
      if (t.cropName.toLowerCase() == parcel.cropName.toLowerCase() && t.activeStep != null) {
        match = t;
        break;
      }
    }

    final String actionLabel;
    final String actionValue;
    if (match != null) {
      actionLabel = match.isOverdue ? 'Tarea vencida' : 'Próxima tarea';
      actionValue = match.isOverdue
          ? 'hace ${match.activeStep!.daysOverdue} día${match.activeStep!.daysOverdue == 1 ? '' : 's'}'
          : (match.isDueToday ? 'Hoy' : match.activeStep!.title);
    } else if (parcel.lastDiagnosisAt != null) {
      actionLabel = 'Último análisis';
      actionValue = _timeAgo(parcel.lastDiagnosisAt!);
    } else {
      actionLabel = 'Sin diagnóstico';
      actionValue = 'Aún no analizado';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 172,
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.onPrimary,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border(left: BorderSide(color: statusInfo.color, width: 3)),
          boxShadow: [
            BoxShadow(color: AppColors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: statusInfo.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.mdLg),
                  ),
                  child: Icon(_cropIcon(parcel.cropName), color: statusInfo.color, size: 18),
                ),
                const Spacer(),
                if (tier != null)
                  _MiniRing(percent: tier, color: statusInfo.color),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              parcel.cropName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
            ),
            Text(
              parcel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxsPlus),
              decoration: BoxDecoration(
                color: statusInfo.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                statusInfo.label,
                style: AppTypography.etiquetaSm.copyWith(
                  color: statusInfo.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
            const Spacer(),
            const Divider(height: AppSpacing.xxl, thickness: 0.5),
            Text(
              actionLabel,
              style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant, fontSize: 9.5),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    actionValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.etiquetaSm.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Anillo circular pequeño. El numero es la representacion estilizada de
/// [_parcelStatusTier], no una medicion — ver esa funcion para el porque.
class _MiniRing extends StatelessWidget {
  final int percent;
  final Color color;
  const _MiniRing({required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              value: percent / 100,
              strokeWidth: 3,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            '$percent',
            style: AppTypography.etiquetaSm.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TreatmentEntity treatment;
  final bool isLast;
  final VoidCallback onTap;
  const _TaskRow({required this.treatment, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    final String badgeLabel;
    if (treatment.isOverdue) {
      dotColor = AppColors.error;
      badgeLabel = 'Vencida';
    } else if (treatment.isDueToday) {
      dotColor = AppColors.burntOrange;
      badgeLabel = 'Hoy';
    } else {
      dotColor = AppColors.forestGreen;
      badgeLabel = 'Mañana';
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    treatment.activeStep!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    treatment.diseaseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxsPlus),
              decoration: BoxDecoration(
                color: dotColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                badgeLabel,
                style: AppTypography.etiquetaSm.copyWith(
                  color: dotColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ilustracion decorativa (marco de escaneo) para la tarjeta de camara.
/// Construida con widgets planos, sin assets de imagen.
class _ScanFrameIllustration extends StatelessWidget {
  const _ScanFrameIllustration();

  @override
  Widget build(BuildContext context) {
    const c = AppColors.white70;
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.eco_rounded, size: 52, color: c),
          Container(
            width: 64,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.homeScanAccent,
              borderRadius: BorderRadius.circular(AppRadius.xs),
              boxShadow: [
                BoxShadow(color: AppColors.homeScanAccent.withValues(alpha: 0.6), blurRadius: 6),
              ],
            ),
          ),
          Positioned(top: 0, left: 0, child: _corner(top: true, left: true)),
          Positioned(top: 0, right: 0, child: _corner(top: true, left: false)),
          Positioned(bottom: 0, left: 0, child: _corner(top: false, left: true)),
          Positioned(bottom: 0, right: 0, child: _corner(top: false, left: false)),
        ],
      ),
    );
  }

  Widget _corner({required bool top, required bool left}) {
    const side = BorderSide(color: AppColors.white70, width: 2.5);
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border(
          top: top ? side : BorderSide.none,
          bottom: !top ? side : BorderSide.none,
          left: left ? side : BorderSide.none,
          right: !left ? side : BorderSide.none,
        ),
      ),
    );
  }
}
