import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../providers/home_providers.dart';

/// Selector de categorías en formato de "burbujitas / pills" horizontales centradas al estilo moderno,
/// ubicado en la parte superior del Home para optimizar el UI/UX de navegación.
class CategorySelector extends ConsumerWidget {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(selectedServiceTypeProvider);
    final currentRole = ref.watch(currentRoleProvider);
    final allowedTypes = currentRole.allowedServiceTypes;
    final availableTypes = ServiceType.values
        .where((type) => allowedTypes.contains(type))
        .toList();

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: availableTypes.asMap().entries.map((entry) {
            final index = entry.key;
            final type = entry.value;
            final isActive = type == selectedType;
            final IconData iconData;

            switch (type) {
              case ServiceType.spareParts:
                iconData = Icons.settings_rounded;
                break;
              case ServiceType.mechanic:
                iconData = Icons.build_rounded;
                break;
              case ServiceType.workshops:
                iconData = Icons.warehouse_rounded;
                break;
            }

            final isLast = index == availableTypes.length - 1;

            return Padding(
              padding: EdgeInsets.only(right: isLast ? 0.0 : 8.0),
              child: _CategoryPill(
                label: type.label,
                icon: iconData,
                isActive: isActive,
                onTap: () {
                  ref.read(selectedServiceTypeProvider.notifier).state = type;
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_CategoryPill> createState() => _CategoryPillState();
}

class _CategoryPillState extends State<_CategoryPill> {
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
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive ? AppColors.primary : Colors.white,
            gradient: widget.isActive
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(30), // Formato cápsula / burbuja
            border: Border.all(
              color: widget.isActive ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isActive
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: widget.isActive ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.4,
                  color: widget.isActive ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
