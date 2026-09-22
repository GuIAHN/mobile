import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Chip seleccionable estándar: opciones de filtro, especialidades,
/// vehículos, filtros activos removibles.
///
/// Sustituye las cuatro variantes hechas a mano que existían en
/// filters_sheet.dart y home_list_header.dart. Fondo seleccionado en
/// `primaryDark` (no `primary`) para mantener 4.5:1 con texto blanco.
class AppChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  /// Si se define, el chip muestra una "x" para removerse (filtro activo).
  final VoidCallback? onRemove;

  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.textPrimary;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: AnimatedContainer(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(
            minHeight: AppSpacing.buttonHeightMd,
          ),
          padding: EdgeInsets.only(
            left: 14,
            right: onRemove != null ? 8 : 14,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: selected ? AppColors.primaryDark : AppColors.border,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  softWrap: true,
                  style: AppTypography.meta.copyWith(
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 4),
                Semantics(
                  button: true,
                  label: 'Quitar $label',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: onRemove,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: foreground.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
