import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/widgets/section_header.dart';
import '../../../../../core/domain/enums/service_type.dart';
import '../../../../../core/providers/current_user_provider.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../../../../core/domain/entities/user_car.dart';
import '../../providers/home_providers.dart';
import '../spare_part_wizard/spare_part_wizard_page.dart';

/// Configuración visual de cada tipo de acción del buscador principal.
class _CategoryConfig {
  final IconData icon;
  final String label;
  final String semanticsLabel;
  final String semanticsHint;

  const _CategoryConfig({
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.semanticsHint,
  });
}

/// Tarjetas de categorías principales del home.
class CategoryGrid extends ConsumerWidget {
  const CategoryGrid({super.key});

  void _handleCategoryTap(
    BuildContext context,
    WidgetRef ref,
    ServiceType type,
    List<UserCar>? garageCars,
  ) {
    HapticFeedback.selectionClick();
    ref.read(selectedServiceTypeProvider.notifier).state = type;
    switch (type) {
      case ServiceType.spareParts:
        final selectedVehicle = ref.read(searchVehicleProvider);
        final displayedVehicle = selectedVehicle ??
            (garageCars == null || garageCars.isEmpty
                ? null
                : garageCars.first);
        SparePartWizardPage.show(
          context,
          initialVehicle: displayedVehicle,
          initialModelId: ref.read(searchVehicleModelIdProvider),
        );
        break;
      case ServiceType.workshops:
        context.push(RouteNames.workshops);
        break;
      case ServiceType.mechanic:
        context.push(RouteNames.mechanics);
        break;
      case ServiceType.storeDashboard:
        break;
    }
  }

  _CategoryConfig _configFor(ServiceType type) {
    switch (type) {
      case ServiceType.spareParts:
        return const _CategoryConfig(
          icon: AppIcons.catalog,
          label: 'Pedir repuesto',
          semanticsLabel: 'Pedir repuesto',
          semanticsHint: 'Cotiza piezas',
        );
      case ServiceType.workshops:
        return const _CategoryConfig(
          icon: AppIcons.workshop,
          label: 'Buscar taller',
          semanticsLabel: 'Buscar taller',
          semanticsHint: 'Opciones cercanas',
        );
      case ServiceType.mechanic:
        return const _CategoryConfig(
          icon: AppIcons.mechanic,
          label: 'Buscar mecánico',
          semanticsLabel: 'Buscar mecánico',
          semanticsHint: 'Servicio a domicilio',
        );
      case ServiceType.storeDashboard:
        return _CategoryConfig(
          icon: AppIcons.dashboard,
          label: type.label,
          semanticsLabel: 'Ver estadísticas',
          semanticsHint: 'Consulta tu rendimiento',
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(currentRoleProvider);
    final selectedType = ref.watch(selectedServiceTypeProvider);
    final garageCars = currentRole.canRequestSpareParts
        ? ref.watch(userCarsProvider).valueOrNull
        : null;
    final allowedTypes = currentRole.allowedServiceTypes;
    final availableTypes = ServiceType.values
        .where((type) => allowedTypes.contains(type))
        .toList();

    if (availableTypes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: '¿Qué buscas hoy?',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final usesAccessibleList =
                MediaQuery.textScalerOf(context).scale(1) >= 1.6;
            Widget cardFor(int index) => _CategoryCard(
                  config: _configFor(availableTypes[index]),
                  isSelected: selectedType == availableTypes[index],
                  usesHorizontalLayout: usesAccessibleList,
                  onTap: () => _handleCategoryTap(
                    context,
                    ref,
                    availableTypes[index],
                    garageCars,
                  ),
                );

            if (usesAccessibleList) {
              return Column(
                children: [
                  for (var i = 0; i < availableTypes.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    SizedBox(width: double.infinity, child: cardFor(i)),
                  ],
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < availableTypes.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(child: cardFor(i)),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final _CategoryConfig config;
  final bool isSelected;
  final bool usesHorizontalLayout;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.config,
    required this.isSelected,
    required this.usesHorizontalLayout,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final animationsEnabled = !MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(20);
    final iconColor =
        widget.isSelected ? AppColors.primary : AppColors.textPrimary;

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.config.semanticsLabel,
      hint: widget.config.semanticsHint,
      onTap: widget.onTap,
      container: true,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: animationsEnabled && _isPressed ? 0.96 : 1,
        duration: animationsEnabled
            ? const Duration(milliseconds: 160)
            : Duration.zero,
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primaryMuted.withValues(alpha: 0.42)
                : AppColors.surface,
            borderRadius: radius,
            border: Border.all(
              color: widget.isSelected ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? AppColors.primary.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: radius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: radius,
              onHighlightChanged: (isPressed) {
                if (_isPressed != isPressed) {
                  setState(() => _isPressed = isPressed);
                }
              },
              onTap: widget.onTap,
              overlayColor: WidgetStatePropertyAll(
                AppColors.primary.withValues(alpha: 0.08),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: widget.usesHorizontalLayout ? 64 : AppSpacing.xl8,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -14,
                      right: -12,
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: AppLineIcon(
                            widget.config.icon,
                            key: ValueKey<String>(
                              'category-watermark-${widget.config.semanticsLabel}',
                            ),
                            size: AppIconSize.hero,
                            color: widget.isSelected
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : AppColors.textPrimary.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(
                        widget.usesHorizontalLayout
                            ? AppSpacing.lg
                            : AppSpacing.md,
                      ),
                      child: widget.usesHorizontalLayout
                          ? _HorizontalCategoryContent(
                              config: widget.config,
                              iconColor: iconColor,
                            )
                          : _VerticalCategoryContent(
                              config: widget.config,
                              iconColor: iconColor,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalCategoryContent extends StatelessWidget {
  const _VerticalCategoryContent({
    required this.config,
    required this.iconColor,
  });

  final _CategoryConfig config;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final titleSlotHeight =
        MediaQuery.textScalerOf(context).scale(AppSpacing.xl3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppLineIcon(
          config.icon,
          size: AppIconSize.feature,
          color: iconColor,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          key: ValueKey<String>('category-title-slot-${config.label}'),
          height: titleSlotHeight,
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              config.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(
                height: 1.2,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HorizontalCategoryContent extends StatelessWidget {
  const _HorizontalCategoryContent({
    required this.config,
    required this.iconColor,
  });

  final _CategoryConfig config;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppLineIcon(
          config.icon,
          size: AppIconSize.feature,
          color: iconColor,
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Text(
            config.label,
            style: AppTypography.title,
          ),
        ),
      ],
    );
  }
}
