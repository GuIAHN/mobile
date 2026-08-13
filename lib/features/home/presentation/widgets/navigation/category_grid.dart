import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/domain/enums/service_type.dart';
import '../../../../../core/providers/current_user_provider.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../providers/home_providers.dart';
import '../spare_part_wizard/spare_part_wizard_page.dart';

/// Ilustración automotriz de cada categoría.
class _CategoryStyle {
  final String? svg;
  final IconData fallbackIcon;

  const _CategoryStyle({
    this.svg,
    required this.fallbackIcon,
  });
}

const _sparePartsArtwork = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
  <g stroke="#A83E05" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
    <path d="M19 8h10l2 5 5 2 5 8-4 2v9H11v-9l-4-2 5-8 5-2 2-5Z"/>
    <circle cx="24" cy="23" r="6"/>
    <path d="M24 17v-4M24 33v-4M18 23h-4M34 23h-4M19.7 18.7l-2.8-2.8M31.1 30.1l-2.8-2.8M28.3 18.7l2.8-2.8M16.9 30.1l2.8-2.8M15 34v6M33 34v6"/>
  </g>
</svg>
''';

const _workshopsArtwork = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
  <g stroke="#A83E05" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
    <path d="M7 18 12 9h24l5 9v22H7V18Z"/>
    <path d="M7 18h34M13 40V27h22v13M17 27l2-6h10l2 6M18 33h12M15 14h18"/>
  </g>
  <circle cx="17" cy="29" r="1.5" fill="#A83E05"/>
  <circle cx="31" cy="29" r="1.5" fill="#A83E05"/>
</svg>
''';

const _mechanicsArtwork = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" fill="none">
  <g stroke="#A83E05" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="21" cy="16" r="6"/>
    <path d="M10 39c1-8 5-12 11-12s10 4 11 12H10ZM15 11v5h12v-5"/>
    <path d="m34 10 3 3-9 9-4 1 1-4 9-9ZM33 11l3 3M29 21l3 3"/>
  </g>
</svg>
''';

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
        final selectedVehicle = ref.read(searchVehicleProvider);
        final garageCars = ref.read(userCarsProvider).valueOrNull;
        final displayedVehicle = selectedVehicle ??
            (garageCars == null || garageCars.isEmpty
                ? null
                : garageCars.first);
        SparePartWizardPage.show(
          context,
          initialVehicle: displayedVehicle,
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
          svg: _sparePartsArtwork,
          fallbackIcon: Icons.settings_outlined,
        );
      case ServiceType.workshops:
        return const _CategoryStyle(
          svg: _workshopsArtwork,
          fallbackIcon: Icons.home_repair_service_outlined,
        );
      case ServiceType.mechanic:
        return const _CategoryStyle(
          svg: _mechanicsArtwork,
          fallbackIcon: Icons.engineering_outlined,
        );
      case ServiceType.storeDashboard:
        return const _CategoryStyle(
          fallbackIcon: Icons.storefront_outlined,
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
    final radius = BorderRadius.circular(10);
    final labelFontSize = widget.isCompact ? 12.5 : 13.5;
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
          elevation: 1.5,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
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
              constraints: const BoxConstraints(minHeight: 140),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isCompact ? 8 : 12,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: widget.isCompact ? 68 : 72,
                      height: widget.isCompact ? 68 : 72,
                      decoration: BoxDecoration(
                        color: AppColors.primaryMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: widget.style.svg == null
                          ? Icon(
                              widget.style.fallbackIcon,
                              size: 38,
                              color: AppColors.primaryInk,
                            )
                          : SvgPicture.string(
                              widget.style.svg!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                              semanticsLabel: widget.label,
                            ),
                    ),
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
