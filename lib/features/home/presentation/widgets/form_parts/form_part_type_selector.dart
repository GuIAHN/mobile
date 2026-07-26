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
          child: GestureDetector(
            onTap: () => onPartTypeSelected(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              height: 102,
              decoration: BoxDecoration(
                color: esSeleccionado ? AppColors.primaryMuted : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: esSeleccionado ? AppColors.primary : AppColors.border,
                  width: esSeleccionado ? 1.5 : 1.0,
                ),
                boxShadow: esSeleccionado
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type.icon,
                    color: esSeleccionado
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    type.label,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: esSeleccionado
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
