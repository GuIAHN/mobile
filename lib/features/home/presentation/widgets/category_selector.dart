import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../providers/home_providers.dart';

class CategorySelector extends ConsumerWidget {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(selectedServiceTypeProvider);
    final currentRole = ref.watch(currentRoleProvider);
    final allowedTypes = currentRole.allowedServiceTypes;

    return Row(
      children: ServiceType.values.where((type) => allowedTypes.contains(type)).map((type) {
        final isActive = type == selectedType;

        // Obtener colores personalizados por categoría para mayor dinamismo
        final Color activeColor;
        final Color activeBgColor;
        final Color shadowColor;
        final IconData iconData;

        switch (type) {
          case ServiceType.mechanic:
            activeColor = AppColors.primary;
            activeBgColor = AppColors.primaryMuted;
            shadowColor = AppColors.primary.withValues(alpha: 0.25);
            iconData = Icons.build_outlined;
            break;
          case ServiceType.spareParts:
            activeColor = AppColors.primary;
            activeBgColor = AppColors.primaryMuted;
            shadowColor = AppColors.primary.withValues(alpha: 0.25);
            iconData = Icons.settings_outlined;
            break;
          case ServiceType.workshops:
            activeColor = AppColors.secondary;
            activeBgColor = AppColors.grey200;
            shadowColor = AppColors.secondary.withValues(alpha: 0.15);
            iconData = Icons.warehouse_outlined;
            break;
        }

        return Expanded(
          child: _CategoryItem(
            label: type.label,
            icon: iconData,
            isActive: isActive,
            activeColor: activeColor,
            activeBgColor: activeBgColor,
            shadowColor: shadowColor,
            onTap: () {
              ref.read(selectedServiceTypeProvider.notifier).state = type;
            },
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final Color activeBgColor;
  final Color shadowColor;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.activeBgColor,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: widget.isActive ? widget.activeBgColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isActive ? widget.activeColor : AppColors.border,
              width: widget.isActive ? 1.5 : 1.0,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: widget.shadowColor,
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: widget.isActive ? Colors.white : AppColors.grey50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: widget.isActive
                      ? widget.activeColor
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12.5,
                  fontWeight:
                      widget.isActive ? FontWeight.w800 : FontWeight.w600,
                  color: widget.isActive
                      ? widget.activeColor
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
