import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';

class StoreProfileStep extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController propietarioController;
  final TextEditingController telefonoController;

  const StoreProfileStep({
    super.key,
    required this.nombreController,
    required this.propietarioController,
    required this.telefonoController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'NOMBRE DE LA TIENDA',
          controller: nombreController,
          hint: 'Ej: Repuestos El Motor',
          prefixIcon: Icons.storefront_outlined,
          textInputAction: TextInputAction.next,
        ),
        AppTextField(
          label: 'NOMBRE DEL PROPIETARIO',
          controller: propietarioController,
          hint: 'Ej: Juan Pérez',
          prefixIcon: Icons.person_outline,
          textInputAction: TextInputAction.next,
        ),
        AppTextField(
          label: 'NÚMERO DE TELÉFONO',
          controller: telefonoController,
          hint: '0414 000 0000',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryMuted, // naranja muy suave
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Esta información será visible para tus clientes al buscar repuestos en la plataforma.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
