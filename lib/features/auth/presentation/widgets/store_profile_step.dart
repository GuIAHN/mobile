import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';

class StoreProfileStep extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController emailController;
  final TextEditingController telefonoController;
  final TextEditingController rifController;
  final bool hasDelivery;
  final ValueChanged<bool> onHasDeliveryChanged;
  final bool isSocial;

  const StoreProfileStep({
    super.key,
    required this.nombreController,
    required this.emailController,
    required this.telefonoController,
    required this.rifController,
    required this.hasDelivery,
    required this.onHasDeliveryChanged,
    this.isSocial = false,
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
          enabled: !isSocial,
          validator: (value) =>
              Validators.required(value, fieldName: 'El nombre de la tienda'),
        ),
        AppTextField(
          label: 'CORREO ELECTRÓNICO',
          controller: emailController,
          hint: 'ejemplo@correo.com',
          prefixIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !isSocial,
          validator: Validators.email,
        ),
        AppTextField(
          label: 'NÚMERO DE TELÉFONO',
          controller: telefonoController,
          hint: '414 123 4567',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          helperText: 'Ingresa el número sin el "0" ni "+58" (ej. 4141234567)',
          validator: Validators.phone,
        ),
        AppTextField(
          label: 'RIF (REGISTRO DE INFORMACIÓN FISCAL)',
          controller: rifController,
          hint: '123456789',
          prefixIcon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          textInputAction:
              isSocial ? TextInputAction.done : TextInputAction.next,
          validator: (value) => Validators.required(value, fieldName: 'El RIF'),
          prefixBuilder: (context, isFocused) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 12),
                Icon(
                  Icons.badge_outlined,
                  size: 20,
                  color:
                      isFocused ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'J',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  height: 20,
                  width: 1,
                  color: AppColors.border,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ofrece servicio de delivery',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: hasDelivery,
                onChanged: onHasDeliveryChanged,
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryMuted,
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
