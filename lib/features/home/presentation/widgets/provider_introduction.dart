import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/domain/enums/service_type.dart';
import 'provider_detail_sheets.dart';

class ProviderIntroduction extends StatelessWidget {
  final String description;
  final ServiceType serviceType;

  const ProviderIntroduction({
    super.key,
    required this.description,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    final title = _providerAboutLabel(serviceType);
    final textStyle = AppTypography.bodySm.copyWith(height: 1.5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: description, style: textStyle),
          maxLines: 3,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth - AppSpacing.lg * 2);
        final isOverflowing = textPainter.didExceedMaxLines;

        return Semantics(
          container: true,
          label: '$title. $description',
          child: Container(
            key: const Key('service-provider-presentation-card'),
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              isOverflowing ? AppSpacing.xs : AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppLineIcon(
                      AppIcons.presentation,
                      size: AppIconSize.inline,
                      color: AppColors.primaryInk,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(title, style: AppTypography.label),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  key: const Key('service-provider-presentation-preview'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
                if (isOverflowing)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const Key('service-provider-presentation-more'),
                      onPressed: () => showProviderAboutSheet(
                        context,
                        title,
                        description,
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(
                          0,
                          AppSpacing.buttonHeightLg,
                        ),
                        padding: const EdgeInsets.only(
                          right: AppSpacing.sm,
                        ),
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text('Leer presentación'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _providerAboutLabel(ServiceType serviceType) => switch (serviceType) {
      ServiceType.spareParts => 'Sobre la tienda',
      ServiceType.workshops || ServiceType.storeDashboard => 'Sobre el taller',
      ServiceType.mechanic => 'Sobre el mecánico',
    };
