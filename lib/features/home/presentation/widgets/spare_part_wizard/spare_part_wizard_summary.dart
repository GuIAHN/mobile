part of 'spare_part_wizard_page.dart';

class _WizardSelectionSummary extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _WizardSelectionSummary({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(eyebrow, style: AppTypography.overline),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.meta,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryInk,
              minimumSize: const Size(48, 48),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
