import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/formatters.dart';

class BillingBalanceCard extends StatelessWidget {
  const BillingBalanceCard({
    super.key,
    required this.amount,
  });

  final double? amount;

  @override
  Widget build(BuildContext context) {
    final isAvailable = amount != null;
    final isPaidUp = isAvailable && amount! <= 0;
    final formattedAmount = isAvailable
        ? Formatters.currency(amount!.clamp(0, double.infinity).toDouble())
        : 'No disponible';
    final statusText = switch ((isAvailable, isPaidUp)) {
      (false, _) => 'No pudimos obtener el saldo en este momento',
      (true, true) => 'Estás al día',
      (true, false) => 'Comisión pendiente por ventas realizadas en la app',
    };
    final statusIcon = switch ((isAvailable, isPaidUp)) {
      (false, _) => Icons.info_outline_rounded,
      (true, true) => Icons.check_circle_outline_rounded,
      (true, false) => Icons.receipt_long_outlined,
    };
    final statusColor = isPaidUp ? AppColors.successInk : AppColors.textMeta;

    return Semantics(
      container: true,
      label: 'Saldo pendiente con GuIA, $formattedAmount. $statusText',
      child: ExcludeSemantics(
        child: Container(
          key: const Key('store-billing-balance-card'),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo pendiente con GuIA',
                      style: GoogleFonts.hankenGrotesk(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formattedAmount,
                      style: GoogleFonts.hankenGrotesk(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(statusIcon, size: 18, color: statusColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            statusText,
                            style: GoogleFonts.hankenGrotesk(
                              color: statusColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
