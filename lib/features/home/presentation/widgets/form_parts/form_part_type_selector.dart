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
    return Column(
      children: [
        for (var index = 0; index < PartType.values.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          _PartTypeTile(
            type: PartType.values[index],
            isSelected: selectedPartType == PartType.values[index],
            onTap: () => onPartTypeSelected(PartType.values[index]),
          ),
        ],
      ],
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
          constraints: const BoxConstraints(minHeight: 76),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected ? AppColors.primary : AppColors.border,
              width: widget.isSelected ? 1.5 : 1.0,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.10),
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
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.type.icon,
                        color: AppColors.textPrimary,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.type.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14,
                              fontWeight: widget.isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.type.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              height: 1.2,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedSwitcher(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      child: widget.isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              key: ValueKey('selected-type'),
                              color: AppColors.primary,
                              size: 23,
                            )
                          : const Icon(
                              Icons.radio_button_unchecked_rounded,
                              key: ValueKey('unselected-type'),
                              color: AppColors.border,
                              size: 23,
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
