import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/domain/enums/part_type.dart';
import '../../../../../core/theme/app_colors.dart';

class FormPartTypeSelector extends StatelessWidget {
  final PartType? selectedPartType;
  final ValueChanged<PartType> onPartTypeSelected;

  const FormPartTypeSelector({
    super.key,
    required this.selectedPartType,
    required this.onPartTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PartType.values.map((type) {
        final esSeleccionado = selectedPartType == type;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _PartTypeTile(
              type: type,
              isSelected: esSeleccionado,
              onTap: () => onPartTypeSelected(type),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PartTypeTile extends StatefulWidget {
  final PartType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _PartTypeTile({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PartTypeTile> createState() => _PartTypeTileState();
}

class _PartTypeTileState extends State<_PartTypeTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          height: 92,
          decoration: BoxDecoration(
            color: widget.isSelected ? AppColors.primaryMuted : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected ? AppColors.primary : AppColors.border,
              width: widget.isSelected ? 1.5 : 1.0,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.type.icon,
                color: widget.isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                widget.type.label,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13.5,
                  fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: widget.isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
