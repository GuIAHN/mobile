import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'request_location_selection.dart';

class RequestLocationPreview extends StatelessWidget {
  final RequestLocationSelection? selection;
  final VoidCallback onTap;

  const RequestLocationPreview({
    super.key,
    required this.selection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final current = selection;
    final semanticsLabel = current == null
        ? 'Elegir ubicación para esta solicitud'
        : 'Cambiar ubicación para esta solicitud. '
            'Ubicación actual: ${current.displayLabel}';

    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          key: const Key('request-location-preview'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryMuted,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusLg,
                      ),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: AppSpacing.iconMd,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current == null
                              ? 'Ubicación de la solicitud'
                              : current.displayLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title,
                        ),
                        if (current == null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Selecciona un punto en el mapa',
                            style: AppTypography.bodySm,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    current == null ? 'Elegir ubicación' : 'Cambiar',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: AppSpacing.iconMd,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
