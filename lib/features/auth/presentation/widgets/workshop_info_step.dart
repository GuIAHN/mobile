import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';

class WorkshopInfoStep extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController emailController;
  final TextEditingController telefonoController;
  final TextEditingController rifController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const WorkshopInfoStep({
    super.key,
    required this.nombreController,
    required this.emailController,
    required this.telefonoController,
    required this.rifController,
    required this.passwordController,
    required this.confirmPasswordController,
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
          hint: '414 123 4567',
          icono: Icons.call_outlined,
          teclado: TextInputType.phone,
          textInputAction: TextInputAction.next,
          helperText: 'Ingresa el número sin el "0" ni "+58" (ej. 4141234567)',
        ),
        _campoRif(
          label: 'RIF / IDENTIFICACIÓN DEL TALLER',
          ctrl: rifController,
          hint: '123456789',
          icono: Icons.badge_outlined,
          teclado: TextInputType.number,
          textInputAction: TextInputAction.next,
        ),
        _campo(
          label: 'CONTRASEÑA',
          ctrl: passwordController,
          hint: '••••••••••',
          icono: Icons.lock_outline,
          ocultar: true,
          textInputAction: TextInputAction.next,
        ),
        _campo(
          label: 'CONFIRMAR CONTRASEÑA',
          ctrl: confirmPasswordController,
          hint: '••••••••••',
          icono: Icons.lock_outline,
          ocultar: true,
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
    bool ocultar = false,
    TextInputType teclado = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    String? helperText,
  }) {
    return AppTextField(
      label: label,
      controller: ctrl,
      hint: hint,
      prefixIcon: icono,
      obscureText: ocultar,
      keyboardType: teclado,
      textInputAction: textInputAction,
      helperText: helperText,
    );
  }

  Widget _campoRif({
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
      prefixBuilder: (context, isFocused) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 12),
            Icon(
              icono,
              size: 20,
              color: isFocused ? AppColors.primary : AppColors.textSecondary,
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
    );
  }
}
