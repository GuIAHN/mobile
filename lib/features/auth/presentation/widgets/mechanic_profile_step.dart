import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';

class MechanicProfileStep extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController telefonoController;
  final TextEditingController emailController;
  final TextEditingController cedulaController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool passwordValida;

  const MechanicProfileStep({
    super.key,
    required this.nombreController,
    required this.telefonoController,
    required this.emailController,
    required this.cedulaController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.passwordValida,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _campo(
          label: 'NOMBRE COMPLETO',
          ctrl: nombreController,
          hint: 'Ej: Marcus Vane',
          icono: Icons.person_outline,
          textInputAction: TextInputAction.next,
        ),
        _campo(
          label: 'NÚMERO DE TELÉFONO',
          ctrl: telefonoController,
          hint: '0414 000 0000',
          icono: Icons.call_outlined,
          teclado: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
        _campo(
          label: 'CORREO ELECTRÓNICO',
          ctrl: emailController,
          hint: 'm.vane@taller.com',
          icono: Icons.mail_outline,
          teclado: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        _campo(
          label: 'CÉDULA DE IDENTIDAD',
          ctrl: cedulaController,
          hint: '12343224',
          icono: Icons.badge_outlined,
          teclado: TextInputType.text,
          textInputAction: TextInputAction.next,
        ),
        _campo(
          label: 'CONTRASEÑA SEGURA',
          ctrl: passwordController,
          hint: '••••••••••',
          icono: Icons.lock_outline,
          obscureText: true,
          textInputAction: TextInputAction.next,
        ),
        _campo(
          label: 'CONFIRMAR CONTRASEÑA',
          ctrl: confirmPasswordController,
          hint: '••••••••••',
          icono: Icons.lock_outline,
          obscureText: true,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 6),
        Text(
          'Mín. 8 caracteres con al menos un número y un símbolo especial.',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11.5,
            color: passwordController.text.isEmpty
                ? AppColors.textSecondary
                : (passwordValida ? AppColors.success : AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
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
    bool obscureText = false,
  }) {
    return AppTextField(
      label: label,
      controller: ctrl,
      hint: hint,
      prefixIcon: icono,
      keyboardType: teclado,
      obscureText: obscureText,
      textInputAction: textInputAction,
    );
  }
}
