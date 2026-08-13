import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Encabezado de sección estándar: barra de acento + ícono opcional + título + acción limpia.
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.action,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(
              icon,
              size: 20,
              color: AppColors.primary,
            ),
          ],
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.h2,
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Botón de acción limpio ("Ver todos ›" / "Gestionar ›").
class SectionHeaderAction extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const SectionHeaderAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.chevron_right_rounded,
  });

  @override
  State<SectionHeaderAction> createState() => _SectionHeaderActionState();
}

class _SectionHeaderActionState extends State<SectionHeaderAction> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapCancel: () => setState(() => _isPressed = false),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.hankenGrotesk(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primary,
                    letterSpacing: -0.1,
                  ),
                ),
                if (widget.icon != null) ...[
                  const SizedBox(width: 1),
                  Icon(
                    widget.icon,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
