import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../notifications/presentation/pages/notifications_page.dart';

/// Encabezado de Inicio: logo + marca + subtitulo, notificaciones, y saludo
/// con icono segun la hora real del dispositivo — todo en el mismo bloque
/// de color verde oscuro con esquinas inferiores redondeadas (estilo de la
/// imagen de referencia).
///
/// Widget fijo (no forma parte del area de scroll): se coloca como hermano
/// de un `Expanded` en la pagina, siguiendo el mismo patron que el resto de
/// las pantallas Aprendiz (ver `ProfileTopBar`, `AgendaAppBar`).
class HomeHeader extends StatelessWidget {
  final String userName;
  final bool hasNotices;

  const HomeHeader({super.key, required this.userName, required this.hasNotices});

  (String, IconData) get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return ('Buenos días', Icons.wb_sunny_rounded);
    if (hour < 19) return ('Buenas tardes', Icons.wb_twilight_rounded);
    return ('Buenas noches', Icons.nightlight_round);
  }

  /// Primer nombre real del usuario (evita saludos de dos lineas cuando el
  /// nombre completo es largo — sigue siendo el nombre real, solo se
  /// muestra la primera palabra, como hace la mayoria de apps).
  String get _firstName {
    final trimmed = userName.trim();
    if (trimmed.isEmpty) return '';
    final first = trimmed.split(RegExp(r'\s+')).first;
    return first[0].toUpperCase() + first.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final (greeting, greetingIcon) = _greeting;
    final firstName = _firstName;
    final greetingText = firstName.isNotEmpty ? '$greeting, $firstName!' : '$greeting!';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.aPrimaryContainer,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.aOnPrimary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco, color: AppColors.aOnPrimary, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AgroGraph IA',
                        style: AppTypography.agendaSubtitle.copyWith(color: AppColors.aOnPrimary),
                      ),
                      Text(
                        'Tu asistente agrícola',
                        style: AppTypography.etiquetaSm.copyWith(fontSize: 11, color: AppColors.aOnPrimaryContainer),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context, NotificationsPage.route()),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.aOnPrimary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_outlined, color: AppColors.aOnPrimary, size: 18),
                      ),
                      if (hasNotices)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: AppColors.aOrange,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.aPrimaryContainer, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    greetingText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.tituloMd.copyWith(fontSize: 18, color: AppColors.aOnPrimary),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(greetingIcon, size: 17, color: AppColors.aOnPrimary.withValues(alpha: 0.85)),
              ],
            ),
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Este es el resumen de tu cultivo.',
                style: AppTypography.etiquetaSm.copyWith(color: AppColors.aOnPrimaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
