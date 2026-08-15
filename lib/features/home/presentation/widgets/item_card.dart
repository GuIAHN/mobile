import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/entities/home_item.dart';
import 'icon_mapper.dart';

class ItemCard extends StatefulWidget {
  final HomeItem item;

  const ItemCard({super.key, required this.item});

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool _isFavorite = false;
  bool _isPressed = false;

  void _onTap() {
    final item = widget.item;
    if (item.id == null) return;

    switch (item.type) {
      case ServiceType.mechanic:
        context.push(RouteNames.mechanicDetailPath(item.id!));
        break;
      case ServiceType.workshops:
        context.push(RouteNames.storeDetailPath(item.id!));
        break;
      case ServiceType.storeDashboard:
        break;
      case ServiceType.spareParts:
        context.push('${RouteNames.storeDetailPath(item.id!)}?type=spareParts');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    const accentColor = AppColors.primaryInk;
    const softBgColor = AppColors.primaryMuted;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.10),
              width: 1.0,
            ),
            boxShadow: AppDecorations.soft,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              _HeroWrapper(
                tag: item.id != null ? 'provider-avatar-${item.id}' : null,
                child: Container(
                  width: 48,
                  height: 48,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: softBgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      width: 1.0,
                    ),
                  ),
                  child: item.photo != null && item.photo!.isNotEmpty
                      ? Image.network(
                          item.photo!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            getIconData(item.iconName),
                            color: accentColor,
                            size: 22,
                          ),
                        )
                      : Icon(
                          getIconData(item.iconName),
                          color: accentColor,
                          size: 22,
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title.copyWith(fontSize: 14.5),
                    ),
                    const SizedBox(height: 3),
                    // Especialidades o detalle
                    Text(
                      item.especialidades.isNotEmpty
                          ? item.especialidades.take(3).join(' · ')
                          : item.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Rating Tag
                        _Tag(
                          backgroundColor: AppColors.warningLight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 13, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Text(
                                item.rating.toStringAsFixed(1),
                                style: AppTypography.meta.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.warningInk,
                                ),
                              ),
                              if (item.reviews > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(${item.reviews})',
                                  style: AppTypography.meta.copyWith(
                                    fontSize: 9.5,
                                    color: AppColors.warningInk,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Distancia Tag
                        _Tag(
                          backgroundColor: AppColors.grey50,
                          border:
                              Border.all(color: AppColors.border, width: 0.5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.near_me_outlined,
                                  size: 11, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                item.distanceKm == null
                                    ? 'Sin distancia'
                                    : '${item.distanceKm!.toStringAsFixed(1)} km',
                                style: AppTypography.meta.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tarifa Tag (solo mecánicos con tarifa)
                        if (item.tarifa != null) ...[
                          _Tag(
                            backgroundColor: AppColors.successLight,
                            child: Text(
                              '${Formatters.currencyCompact(item.tarifa!)}/h',
                              style: AppTypography.meta.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.successInk,
                              ),
                            ),
                          ),
                        ],

                        // Delivery Tag
                        if (item.hasDelivery) ...[
                          _Tag(
                            backgroundColor: AppColors.successLight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_shipping_rounded,
                                    size: 11, color: AppColors.successInk),
                                const SizedBox(width: 4),
                                Text(
                                  'Delivery',
                                  style: AppTypography.meta.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.successInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Botón Favorito (target táctil ≥44px + semántica de toggle)
              Semantics(
                button: true,
                label:
                    _isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isFavorite = !_isFavorite);
                  },
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _isFavorite
                              ? AppColors.primaryMuted
                              : AppColors.grey50,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isFavorite
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.border,
                            width: 1.0,
                          ),
                        ),
                        child: AnimatedScale(
                          scale: _isFavorite ? 1.0 : 0.9,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: _isFavorite
                                ? AppColors.primary
                                : AppColors.textDisabled,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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

class _Tag extends StatelessWidget {
  final Color backgroundColor;
  final Widget child;
  final BoxBorder? border;

  const _Tag({
    required this.backgroundColor,
    required this.child,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: border ??
            Border.all(
              color: AppColors.primary.withValues(alpha: 0.10),
              width: 0.8,
            ),
      ),
      child: child,
    );
  }
}
