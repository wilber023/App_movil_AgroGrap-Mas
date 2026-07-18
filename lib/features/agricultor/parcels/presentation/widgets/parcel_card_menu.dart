import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/security/local_auth_gate.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../diagnosis/presentation/bloc/diagnosis_bloc.dart';
import '../../../diagnosis/presentation/pages/diagnosis_page.dart';
import '../../domain/entities/parcel_entity.dart';
import '../bloc/parcel_bloc.dart';
import '../pages/parcel_detail_page.dart';

/// Menú de tres puntos de cada tarjeta en [ParcelsPage]: ver detalle, nuevo
/// diagnóstico, o eliminar (con reautenticación biométrica/PIN, MASVS-AUTH).
class ParcelCardMenu extends StatelessWidget {
  const ParcelCardMenu({super.key, required this.parcel});

  final ParcelEntity parcel;

  @override
  Widget build(BuildContext context) {
    final p = parcel;
    return SizedBox(
      width: 48,
      height: 48,
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert_outlined,
          color: AppColors.parcelsBorderLight,
          size: 16,
        ),
        onSelected: (value) {
          if (value == 'detalle') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ParcelDetailPage(parcel: p)),
            );
          }
          if (value == 'diagnostico') {
            context.read<DiagnosisBloc>().add(const DiagnosisReset());
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    DiagnosisPage(parcelId: p.seleccionId, parcelName: p.name),
              ),
            );
          }
          if (value == 'eliminar') {
            _confirmDelete(context, p);
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'detalle', child: Text('Ver detalle')),
          const PopupMenuItem(
            value: 'diagnostico',
            child: Text('Nuevo diagnóstico'),
          ),
          PopupMenuItem(
            value: 'eliminar',
            child: Text(
              'Eliminar parcela',
              style: TextStyle(color: AppColors.burntOrange),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ParcelEntity p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar parcela'),
        content: Text(
          '¿Seguro que deseas eliminar "${p.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // MASVS-AUTH: reautenticación adicional antes de una operación
              // destructiva e irreversible.
              final authorized = await LocalAuthGate().authenticate(
                localizedReason:
                    'Confirma tu identidad para eliminar esta parcela',
              );
              if (!authorized || !context.mounted) return;
              context.read<ParcelBloc>().add(
                ParcelDeleteRequested(seleccionId: p.seleccionId),
              );
            },
            child: Text(
              'Eliminar',
              style: TextStyle(color: AppColors.burntOrange),
            ),
          ),
        ],
      ),
    );
  }
}
