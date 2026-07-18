import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

class EconomicsPage extends StatelessWidget {
  const EconomicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for financial movements
    final movements = [
      {
        'title': 'Venta de Cosecha - Tomate',
        'date': '05 Jun 2026',
        'amount': 2450.00,
        'isIncome': true,
      },
      {
        'title': 'Compra de Fungicida',
        'date': '03 Jun 2026',
        'amount': 120.50,
        'isIncome': false,
      },
      {
        'title': 'Pago de Jornales',
        'date': '01 Jun 2026',
        'amount': 450.00,
        'isIncome': false,
      },
      {
        'title': 'Subsidio Agricola',
        'date': '28 May 2026',
        'amount': 800.00,
        'isIncome': true,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Economia Agricola'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xxlPlus),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGeneralBalanceCard(),
            const SizedBox(height: AppSpacing.xhuge),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Registrar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lgXl),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: const Text('Reporte'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lgXl),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.giant),
            Text(
              'Historial de Movimientos',
              style: AppTypography.tituloMd.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: AppSpacing.xxlPlus),
            ...movements.map((movement) => _buildMovementItem(movement)),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xhuge),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xlPlus),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance General',
                style: AppTypography.labelMd.copyWith(color: AppColors.onPrimaryContainer),
              ),
              const Icon(Icons.account_balance_wallet_rounded, color: AppColors.onPrimaryContainer),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            '\$2,679.50',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.onPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xhuge),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingresos Mensuales',
                      style: AppTypography.etiquetaSm.copyWith(color: AppColors.onPrimaryContainer),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      '\$3,250.00',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gastos Mensuales',
                      style: AppTypography.etiquetaSm.copyWith(color: AppColors.onPrimaryContainer),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      '\$570.50',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMovementItem(Map<String, dynamic> movement) {
    final isIncome = movement['isIncome'] as bool;
    final amount = movement['amount'] as double;
    final prefix = isIncome ? '+' : '-';
    final amountColor = isIncome ? AppColors.forestGreen : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.lgXl),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxlPlus, vertical: AppSpacing.md),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isIncome ? AppColors.statusHealthyBg : AppColors.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: isIncome ? AppColors.forestGreen : AppColors.error,
            size: 20,
          ),
        ),
        title: Text(
          movement['title'] as String,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            movement['date'] as String,
            style: AppTypography.etiquetaSm.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
        trailing: Text(
          '$prefix\$${amount.toStringAsFixed(2)}',
          style: AppTypography.labelMd.copyWith(
            color: amountColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
