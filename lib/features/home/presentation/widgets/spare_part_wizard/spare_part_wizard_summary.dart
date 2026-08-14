part of 'spare_part_wizard_page.dart';

class _WizardSelectionSummary extends StatelessWidget {
  final IconData icon;
  final String? imageUrl;
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
    this.imageUrl,
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
          _SummaryLeading(icon: icon, imageUrl: imageUrl),
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

class _SummaryLeading extends StatelessWidget {
  final IconData icon;
  final String? imageUrl;

  const _SummaryLeading({required this.icon, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(icon, color: AppColors.primary, size: 23);
    if (imageUrl != null) {
      return SizedBox(
        key: const Key('wizard-summary-brand-logo'),
        width: 56,
        height: 42,
        child: ExcludeSemantics(
          child: Image.network(
            imageUrl!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => fallback,
          ),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.primaryMuted,
        shape: BoxShape.circle,
      ),
      child: fallback,
    );
  }
}

class _WizardStepIntro extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;

  const _WizardStepIntro({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(width: 7),
            Text(
              eyebrow,
              style: AppTypography.overline.copyWith(
                color: AppColors.primaryInk,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(title, style: AppTypography.h1),
        const SizedBox(height: 6),
        Text(
          description,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _WizardSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String helper;
  final String? badge;

  const _WizardSectionHeader({
    required this.icon,
    required this.title,
    required this.helper,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primaryMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryInk),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.title),
              const SizedBox(height: 1),
              Text(helper, style: AppTypography.meta),
            ],
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(badge!, style: AppTypography.meta),
          ),
        ],
      ],
    );
  }
}
