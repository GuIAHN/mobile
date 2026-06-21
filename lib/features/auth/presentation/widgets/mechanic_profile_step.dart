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
  final String cedulaTipo;
  final ValueChanged<String> onCedulaTipoChanged;

  const MechanicProfileStep({
    super.key,
    required this.nombreController,
    required this.telefonoController,
    required this.emailController,
    required this.cedulaController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.passwordValida,
    required this.cedulaTipo,
    required this.onCedulaTipoChanged,
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
          hint: '414 123 4567',
          icono: Icons.call_outlined,
          teclado: TextInputType.phone,
          textInputAction: TextInputAction.next,
          helperText: 'Ingresa el número sin el "0" ni "+58" (ej. 4141234567)',
        ),
        _campo(
          label: 'CORREO ELECTRÓNICO',
          ctrl: emailController,
          hint: 'm.vane@taller.com',
          icono: Icons.mail_outline,
          teclado: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        _campoCedula(
          label: 'CÉDULA DE IDENTIDAD',
          ctrl: cedulaController,
          hint: '12343224',
          icono: Icons.badge_outlined,
          teclado: TextInputType.number,
          textInputAction: TextInputAction.next,
          cedulaTipo: cedulaTipo,
          onCedulaTipoChanged: onCedulaTipoChanged,
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
    String? helperText,
  }) {
    return AppTextField(
      label: label,
      controller: ctrl,
      hint: hint,
      prefixIcon: icono,
      keyboardType: teclado,
      obscureText: obscureText,
      textInputAction: textInputAction,
      helperText: helperText,
    );
  }

  Widget _campoCedula({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required IconData icono,
    required String cedulaTipo,
    required ValueChanged<String> onCedulaTipoChanged,
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
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: cedulaTipo,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
                dropdownColor: Colors.white,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onCedulaTipoChanged(newValue);
                  }
                },
                items: <String>['V', 'E'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
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
