import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';

class MechanicProfileStep extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController telefonoController;
  final TextEditingController emailController;
  final TextEditingController cedulaController;
  final String cedulaTipo;
  final ValueChanged<String> onCedulaTipoChanged;
  final bool isSocial;

  const MechanicProfileStep({
    super.key,
    required this.nombreController,
    required this.telefonoController,
    required this.emailController,
    required this.cedulaController,
    required this.cedulaTipo,
    required this.onCedulaTipoChanged,
    this.isSocial = false,
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
          enabled: !isSocial,
          validator: (value) =>
              Validators.required(value, fieldName: 'El nombre'),
        ),
        _campo(
          label: 'NÚMERO DE TELÉFONO',
          ctrl: telefonoController,
          hint: '414 123 4567',
          icono: Icons.call_outlined,
          teclado: TextInputType.phone,
          textInputAction:
              isSocial ? TextInputAction.next : TextInputAction.next,
          helperText: 'Ingresa el número sin el "0" ni "+58" (ej. 4141234567)',
          validator: Validators.phone,
        ),
        _campo(
          label: 'CORREO ELECTRÓNICO',
          ctrl: emailController,
          hint: 'm.vane@taller.com',
          icono: Icons.mail_outline,
          teclado: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !isSocial,
          validator: Validators.email,
        ),
        _campoCedula(
          label: 'CÉDULA DE IDENTIDAD',
          ctrl: cedulaController,
          hint: '12343224',
          icono: Icons.badge_outlined,
          teclado: TextInputType.number,
          textInputAction:
              isSocial ? TextInputAction.done : TextInputAction.next,
          cedulaTipo: cedulaTipo,
          onCedulaTipoChanged: onCedulaTipoChanged,
          validator: (value) =>
              Validators.required(value, fieldName: 'La cédula'),
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
    String? helperText,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return AppTextField(
      label: label,
      controller: ctrl,
      hint: hint,
      prefixIcon: icono,
      keyboardType: teclado,
      textInputAction: textInputAction,
      helperText: helperText,
      enabled: enabled,
      validator: validator,
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
    String? Function(String?)? validator,
  }) {
    return AppTextField(
      label: label,
      controller: ctrl,
      hint: hint,
      prefixIcon: icono,
      keyboardType: teclado,
      textInputAction: textInputAction,
      validator: validator,
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
                items: <String>['V', 'E']
                    .map<DropdownMenuItem<String>>((String value) {
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
