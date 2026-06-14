import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';

class WorkshopInfoStep extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController emailController;
  final TextEditingController telefonoController;

  const WorkshopInfoStep({
    super.key,
    required this.nombreController,
    required this.emailController,
    required this.telefonoController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _campo(
          label: 'NOMBRE DEL TALLER',
          ctrl: nombreController,
          hint: 'Ej: Motores Élite',
          icono: Icons.storefront_outlined,
          textInputAction: TextInputAction.next,
        ),
        _campo(
          label: 'CORREO ELECTRÓNICO',
          ctrl: emailController,
          hint: 'ejemplo@correo.com',
          icono: Icons.mail_outline,
          teclado: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        _campo(
          label: 'NÚMERO DE TELÉFONO',
          ctrl: telefonoController,
          hint: '0414 000 0000',
          icono: Icons.call_outlined,
          teclado: TextInputType.phone,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 8),
        // Nota informativa
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10), // naranjaSuave
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
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Esta información será visible para tus clientes en los '
                  'reportes de diagnóstico y facturas generadas por el sistema.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _campo({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required IconData icono,
    TextInputType teclado = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return AppTextField(
      label: label,
      controller: ctrl,
      hint: hint,
      prefixIcon: icono,
      keyboardType: teclado,
      textInputAction: textInputAction,
    );
  }
}
