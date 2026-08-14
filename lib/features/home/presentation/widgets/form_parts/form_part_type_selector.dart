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
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 350;
        final tiles = PartType.values
            .map(
              (type) => _PartTypeTile(
                type: type,
                isSelected: selectedPartType == type,
                onTap: () => onPartTypeSelected(type),
              ),
            )
            .toList();
        if (stack) {
          return Column(
            children: [
              for (var index = 0; index < tiles.length; index++) ...[
                if (index > 0) const SizedBox(height: 8),
                tiles[index],
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var index = 0; index < tiles.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(child: tiles[index]),
            ],
          ],
        );
      },
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.type.label + ', ' + widget.type.description,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 94),
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
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (value) => setState(() => _isPressed = value),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.type.icon,
                          color: widget.isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.type.label,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: widget.isSelected
                                ? FontWeight.w800
                                : FontWeight.w700,
                            color: widget.isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.type.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 10.5,
                            height: 1.15,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    if (widget.isSelected)
                      const Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 18,
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
