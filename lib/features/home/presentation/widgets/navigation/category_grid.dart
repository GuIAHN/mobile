import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/domain/enums/service_type.dart';
import '../../../../../core/providers/current_user_provider.dart';
import '../../../../../core/router/route_names.dart';
import '../../providers/home_providers.dart';
import '../spare_part_wizard/spare_part_wizard_page.dart';

/// Ilustración de cada categoría: icono Material con su color de acento.
class _CategoryStyle {
  final IconData icon;

  const _CategoryStyle({required this.icon});
}

/// Tarjetas de categorías del home.
/// Cada tarjeta REDIRIGE a su flujo correspondiente:
/// - Repuestos  → flujo de solicitud de repuesto (wizard)
/// - Talleres   → pantalla completa de talleres
/// - Mecánicos  → pantalla completa de mecánicos
class CategoryGrid extends ConsumerWidget {
  const CategoryGrid({super.key});

  void _handleCategoryTap(
      BuildContext context, WidgetRef ref, ServiceType type) {
    HapticFeedback.selectionClick();
    switch (type) {
      case ServiceType.spareParts:
        SparePartWizardPage.show(
          context,
          initialVehicle: ref.read(searchVehicleProvider),
          initialVariantId: ref.read(searchVehicleVariantIdProvider),
        );
        break;
      case ServiceType.workshops:
        context.push(RouteNames.workshops);
        break;
      case ServiceType.mechanic:
        context.push(RouteNames.mechanics);
        break;
      case ServiceType.storeDashboard:
        ref.read(selectedServiceTypeProvider.notifier).state = type;
        break;
    }
  }

  _CategoryStyle _styleFor(ServiceType type) {
    switch (type) {
      case ServiceType.spareParts:
        return const _CategoryStyle(
          icon: Icons.settings_outlined,
        );
      case ServiceType.workshops:
        return const _CategoryStyle(
          icon: Icons.home_repair_service_outlined,
        );
      case ServiceType.mechanic:
        return const _CategoryStyle(
          icon: Icons.engineering_outlined,
        );
      case ServiceType.storeDashboard:
        return const _CategoryStyle(
          icon: Icons.storefront_outlined,
        );
    }
  }

  String _actionLabel(ServiceType type) {
    switch (type) {
      case ServiceType.spareParts:
        return 'Solicitar repuesto';
      case ServiceType.workshops:
        return 'Buscar talleres';
      case ServiceType.mechanic:
        return 'Buscar mecánicos';
      case ServiceType.storeDashboard:
        return type.label;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(currentRoleProvider);
    final allowedTypes = currentRole.allowedServiceTypes;
    final availableTypes = ServiceType.values
        .where((type) => allowedTypes.contains(type))
        .toList();

    if (availableTypes.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < availableTypes.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _CategoryCard(
                  label: _actionLabel(availableTypes[i]),
                  style: _styleFor(availableTypes[i]),
                  isCompact: constraints.maxWidth < 400,
                  onTap: () =>
                      _handleCategoryTap(context, ref, availableTypes[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String label;
  final _CategoryStyle style;
  final bool isCompact;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.style,
    required this.isCompact,
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
    final labelFontSize = widget.isCompact ? 12.0 : 13.0;
    final allowExpandedLabel =
        MediaQuery.textScalerOf(context).scale(labelFontSize) >
            labelFontSize * 1.5;

    return Semantics(
      button: true,
      label: widget.label,
      onTap: widget.onTap,
      container: true,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: animationsEnabled && _isPressed ? 0.97 : 1,
        duration: animationsEnabled
            ? const Duration(milliseconds: 160)
            : Duration.zero,
        curve: Curves.easeOut,
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: const BorderSide(color: AppColors.border),
          ),
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
              constraints: const BoxConstraints(minHeight: 112),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isCompact ? 8 : 12,
                  vertical: 14,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryMuted,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        widget.style.icon,
                        size: 24,
                        color: AppColors.primaryInk,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.label,
                      maxLines: allowExpandedLabel ? 6 : 2,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: labelFontSize,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.primaryInk,
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
