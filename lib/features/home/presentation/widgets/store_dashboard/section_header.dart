import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_tokens.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      title,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppTokens.textPrimary,
        letterSpacing: -0.4,
      ),
    );

    if (trailing == null) return titleWidget;

    final usesLargeText = MediaQuery.textScalerOf(context).scale(18) > 24;
    if (usesLargeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget,
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: trailing!),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: titleWidget),
        const SizedBox(width: 12),
        trailing!,
      ],
    );
  }
}

class PeriodSelector extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const PeriodSelector({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTokens.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTokens.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                size: 16, color: AppTokens.textSecondary),
          ],
        ),
      ),
    );
  }
}

Future<int?> showDashboardPeriodBottomSheet(
  BuildContext context, {
  required int currentDays,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: AppTokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTokens.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Seleccionar período',
            style: GoogleFonts.hankenGrotesk(
              color: AppTokens.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final days in const [7, 15, 30])
            ListTile(
              minTileHeight: 48,
              onTap: () => Navigator.pop(context, days),
              title: Text(
                'Últimos $days días',
                style: GoogleFonts.hankenGrotesk(
                  color: days == currentDays
                      ? AppTokens.accent
                      : AppTokens.textPrimary,
                  fontWeight:
                      days == currentDays ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: days == currentDays
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppTokens.accent,
                    )
                  : null,
            ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
