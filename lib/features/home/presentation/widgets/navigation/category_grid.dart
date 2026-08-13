import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/domain/enums/service_type.dart';
import '../../../../../core/providers/current_user_provider.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../providers/home_providers.dart';
import '../spare_part_wizard/spare_part_wizard_page.dart';

/// Configuración visual de cada tipo de acción del buscador principal.
class _CategoryConfig {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconBgColor;

  const _CategoryConfig({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconBgColor,
  });
}

/// Tarjetas de categorías principales del home sin borde contenedor.
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

  _CategoryConfig _configFor(ServiceType type) {
    switch (type) {
      case ServiceType.spareParts:
        return _CategoryConfig(
          icon: Icons.handyman_rounded,
          label: 'Pedir repuesto',
          subtitle: 'Cotiza piezas y repuestos para tu vehículo',
          iconBgColor: AppColors.primaryMuted.withValues(alpha: 0.85),
        );
      case ServiceType.workshops:
        return _CategoryConfig(
          icon: Icons.storefront_rounded,
          label: 'Buscar taller',
          subtitle: 'Encuentra talleres mecánicos y diagnóstico',
          iconBgColor: AppColors.primaryMuted.withValues(alpha: 0.85),
        );
      case ServiceType.mechanic:
        return _CategoryConfig(
          icon: Icons.engineering_rounded,
          label: 'Buscar mecánico',
          subtitle: 'Mecánicos calificados con servicio a domicilio',
          iconBgColor: AppColors.primaryMuted.withValues(alpha: 0.85),
        );
      case ServiceType.storeDashboard:
        return _CategoryConfig(
          icon: Icons.dashboard_rounded,
          label: type.label,
          subtitle: 'Gestión completa de tienda y cotizaciones',
          iconBgColor: AppColors.primaryMuted.withValues(alpha: 0.85),
        );
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
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _CategoryCard(
                  config: _configFor(availableTypes[i]),
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
  final _CategoryConfig config;
  final bool isCompact;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.config,
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

    return Semantics(
      button: true,
      label: widget.config.label,
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
            color: Colors.white,
            borderRadius: radius,
            // SIN BORDE EXTERNO según requerimiento del usuario
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
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
                constraints: const BoxConstraints(minHeight: 148),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Fila superior: ícono + flecha indicador ────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: widget.isCompact ? 46 : 52,
                            height: widget.isCompact ? 46 : 52,
                            decoration: BoxDecoration(
                              color: widget.config.iconBgColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              widget.config.icon,
                              size: widget.isCompact ? 24 : 28,
                              color: AppColors.primary,
                            ),
                          ),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.primaryMuted.withValues(alpha: 0.80),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Título principal ──────────────────────────────
                      Text(
                        widget.config.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // ── Subtítulo indicativo ──────────────────────────
                      Text(
                        widget.config.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          letterSpacing: -0.1,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
