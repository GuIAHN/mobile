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
/// Se renderiza dentro de un fondo redondeado tintado (estilo "chip").
class _CategoryStyle {
  final IconData icon;
  final Color accentColor;

  const _CategoryStyle({required this.icon, required this.accentColor});
}

/// Tarjetas de categorías del home.
/// Cada tarjeta REDIRIGE a su flujo correspondiente:
/// - Repuestos  → flujo de solicitud de repuesto (wizard)
/// - Talleres   → pantalla completa de talleres
/// - Mecánicos  → pantalla completa de mecánicos
class CategoryGrid extends ConsumerWidget {
  const CategoryGrid({super.key});

  void _handleCategoryTap(BuildContext context, WidgetRef ref, ServiceType type) {
    HapticFeedback.selectionClick();
    switch (type) {
      case ServiceType.spareParts:
        SparePartWizardPage.show(context);
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

  /// Celeste cielo del trazo inferior de la "G" del logo.
  static const Color _logoBlue = Color(0xFF4FC3F7);

  _CategoryStyle _styleFor(ServiceType type) {
    switch (type) {
      case ServiceType.spareParts:
        return const _CategoryStyle(
          icon: Icons.build_outlined,
          accentColor: _logoBlue,
        );
      case ServiceType.workshops:
        return const _CategoryStyle(
          icon: Icons.home_repair_service_outlined,
          accentColor: _logoBlue,
        );
      case ServiceType.mechanic:
        return const _CategoryStyle(
          icon: Icons.engineering_outlined,
          accentColor: _logoBlue,
        );
      case ServiceType.storeDashboard:
        return const _CategoryStyle(
          icon: Icons.storefront_outlined,
          accentColor: _logoBlue,
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < availableTypes.length; i++) ...[
          if (i > 0) const SizedBox(width: 20),
          _CategoryCard(
            label: availableTypes[i].label,
            style: _styleFor(availableTypes[i]),
            onTap: () => _handleCategoryTap(context, ref, availableTypes[i]),
          ),
        ],
      ],
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String label;
  final _CategoryStyle style;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.style,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SizedBox(
          width: 84,
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: widget.style.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Icon(
                    widget.style.icon,
                    size: 34,
                    color: widget.style.accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
