import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../shared/widgets/section_header.dart';
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
  final String semanticsLabel;
  final String subtitle;
  final Color iconBgColor;

  const _CategoryConfig({
    required this.icon,
    required this.label,
    required this.semanticsLabel,
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
        return const _CategoryConfig(
          icon: Icons.handyman_rounded,
          label: 'Pedir repuesto',
          semanticsLabel: 'Pedir repuesto',
          subtitle: 'Cotiza piezas',
          iconBgColor: Colors.transparent,
        );
      case ServiceType.workshops:
        return const _CategoryConfig(
          icon: Icons.storefront_rounded,
          label: 'Buscar taller',
          semanticsLabel: 'Buscar taller',
          subtitle: 'Opciones cercanas',
          iconBgColor: Colors.transparent,
        );
      case ServiceType.mechanic:
        return const _CategoryConfig(
          icon: Icons.engineering_rounded,
          label: 'Buscar mecánico',
          semanticsLabel: 'Buscar mecánico',
          subtitle: 'Servicio a domicilio',
          iconBgColor: Colors.transparent,
        );
      case ServiceType.storeDashboard:
        return _CategoryConfig(
          icon: Icons.dashboard_rounded,
          label: type.label,
          semanticsLabel: 'Ver estadísticas',
          subtitle: 'Tu rendimiento',
          iconBgColor: Colors.transparent,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: '¿Qué buscas hoy?',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            Widget cardFor(int index) => _CategoryCard(
                  config: _configFor(availableTypes[index]),
                  isCompact: constraints.maxWidth < 400,
                  onTap: () =>
                      _handleCategoryTap(context, ref, availableTypes[index]),
                );

            final usesAccessibleList =
                MediaQuery.textScalerOf(context).scale(1) >= 1.6;
            if (usesAccessibleList) {
              return Column(
                children: [
                  for (var i = 0; i < availableTypes.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
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
                    if (i > 0) const SizedBox(width: 10),
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
      label: widget.config.semanticsLabel,
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
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.22),
              width: 1.25,
            ),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Ícono centrado ─────────────────────────────
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: widget.isCompact ? 46 : 52,
                          height: widget.isCompact ? 46 : 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: widget.config.iconBgColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            widget.config.icon,
                            size: widget.isCompact ? 28 : 40,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Título principal ──────────────────────────────
                      Text(
                        widget.config.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
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
                        textAlign: TextAlign.center,
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
