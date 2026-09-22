import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/entities/home_item.dart';
import 'provider_photo.dart';

class ItemCard extends StatefulWidget {
  final HomeItem item;

  const ItemCard({super.key, required this.item});

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool _isPressed = false;

  void _onTap() {
    final item = widget.item;
    if (item.id == null) return;

    switch (item.type) {
      case ServiceType.mechanic:
        context.push(RouteNames.mechanicDetailPath(item.id!));
        break;
      case ServiceType.workshops:
        context.push(RouteNames.workshopDetailPath(item.id!));
        break;
      case ServiceType.storeDashboard:
        break;
      case ServiceType.spareParts:
        context.push(RouteNames.storeDetailPath(item.id!));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final providerType = item.type == ServiceType.workshops
        ? 'Taller'
        : item.type == ServiceType.mechanic
            ? 'Mecánico'
            : item.type.label;

    return Semantics(
      button: true,
      label:
          '$providerType ${item.name}, ${item.rating.toStringAsFixed(1)} estrellas',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: _onTap,
        child: AnimatedScale(
          scale: _isPressed && !reduceMotion ? 0.98 : 1,
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 120),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border, width: 0.8),
              boxShadow: AppDecorations.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _HeroWrapper(
                        tag: item.id != null
                            ? 'provider-avatar-${item.id}'
                            : null,
                        child: ProviderPhoto(
                          photoUrl: item.photo,
                          providerName: item.name,
                          networkKey: Key('provider-list-photo-${item.id}'),
                          fallback: ColoredBox(
                            key: Key('provider-list-fallback-${item.id}'),
                            color: AppColors.primaryMuted,
                            child: Center(
                              child: AppLineIcon(
                                item.type == ServiceType.workshops
                                    ? AppIcons.workshop
                                    : AppIcons.mechanic,
                                size: AppIconSize.feature,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: _TypeLabel(label: providerType),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(
                          fontSize: 14,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.especialidades.isNotEmpty
                            ? item.especialidades.take(2).join(' · ')
                            : item.detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 11.5,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const AppLineIcon(
                            AppIcons.rating,
                            size: AppIconSize.inline,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.rating.toStringAsFixed(1),
                            style: AppTypography.meta.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (item.reviews > 0)
                            Flexible(
                              child: Text(
                                ' (${item.reviews})',
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.meta,
                              ),
                            ),
                          const Spacer(),
                          const AppLineIcon(
                            AppIcons.distance,
                            size: AppIconSize.inline,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              item.distanceKm == null
                                  ? '—'
                                  : '${item.distanceKm!.toStringAsFixed(1)} km',
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.meta.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.tarifa != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${Formatters.currencyCompact(item.tarifa!)}/h',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.meta.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeLabel extends StatelessWidget {
  final String label;

  const _TypeLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTypography.meta.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Envuelve en Hero solo si hay tag (los items sin id no navegan a detalle).
class _HeroWrapper extends StatelessWidget {
  final String? tag;
  final Widget child;

  const _HeroWrapper({required this.tag, required this.child});

  @override
  Widget build(BuildContext context) {
    if (tag == null) return child;
    return Hero(tag: tag!, child: child);
  }
}
