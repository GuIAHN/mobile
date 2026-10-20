import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../domain/entities/provider_detail.dart';
import 'provider_detail_widgets.dart';

Future<void> showProviderServicesSheet(
    BuildContext context, List<String> specialties,
    {required String title}) {
  return _showDetailSheet(
    context,
    title: title,
    child: _ServicesSheetContent(specialties: specialties),
  );
}

Future<void> showProviderAboutSheet(
  BuildContext context,
  String title,
  String description,
) {
  return _showDetailSheet(
    context,
    title: title,
    child: Text(
      description,
      key: const Key('service-provider-presentation-full'),
      style: AppTypography.body,
    ),
  );
}

Future<void> showProviderLocationSheet(
  BuildContext context,
  ProviderDetail detail,
) {
  return _showDetailSheet(
    context,
    title: 'Ubicación',
    maxHeightFactor: 0.82,
    child: DetailLocationCard(
      direccion: detail.direccion,
      lat: detail.lat,
      lng: detail.lng,
      embedded: true,
    ),
  );
}

Future<void> _showDetailSheet(
  BuildContext context, {
  required String title,
  required Widget child,
  double maxHeightFactor = 0.72,
}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    sheetAnimationStyle: AnimationStyle(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
      reverseDuration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
    ),
    builder: (context) => ConstrainedBox(
      key: const Key('provider-detail-sheet'),
      constraints: BoxConstraints(
        minWidth: MediaQuery.sizeOf(context).width,
        maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
      ),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppDecorations.sheet),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: AppSpacing.xl4,
              height: AppSpacing.xs,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xl6),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTypography.h2,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      key: const Key('provider-detail-sheet-close'),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Cerrar',
                      constraints: const BoxConstraints(
                        minWidth: AppSpacing.buttonHeightMd,
                        minHeight: AppSpacing.buttonHeightMd,
                      ),
                      icon: const AppLineIcon(
                        AppIcons.close,
                        size: AppIconSize.leading,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ServicesSheetContent extends StatelessWidget {
  final List<String> specialties;

  const _ServicesSheetContent({required this.specialties});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < specialties.length; index++) ...[
          ConstrainedBox(
            constraints:
                const BoxConstraints(minHeight: AppSpacing.buttonHeightMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppLineIcon(
                  AppIcons.selected,
                  size: AppIconSize.action,
                  color: AppColors.primaryInk,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    specialties[index],
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (index < specialties.length - 1)
            const Divider(height: 1, color: AppColors.border),
        ],
      ],
    );
  }
}
