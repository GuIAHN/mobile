import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Dedicated registration step for password creation and its live feedback.
class AccountSecurityStep extends StatelessWidget {
  const AccountSecurityStep({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    this.isSocial = false,
    this.socialProvider,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isSocial;
  final String? socialProvider;

  @override
  Widget build(BuildContext context) {
    if (isSocial) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: AppColors.success,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tu cuenta está protegida',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Usarás ${_providerLabel(socialProvider)} para iniciar sesión. No necesitas crear otra contraseña.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListenableBuilder(
      listenable:
          Listenable.merge([passwordController, confirmPasswordController]),
      builder: (context, _) {
        final password = passwordController.text;
        final confirmation = confirmPasswordController.text;
        final hasMinLength = password.length >= 8;
        final hasNumber = password.contains(RegExp(r'[0-9]'));
        final hasSymbol =
            password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
        final matches = confirmation.isNotEmpty && confirmation == password;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'CONTRASEÑA',
              controller: passwordController,
              hint: '••••••••••',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.visiblePassword,
              validator: Validators.password,
            ),
            AppTextField(
              label: 'CONFIRMAR CONTRASEÑA',
              controller: confirmPasswordController,
              hint: '••••••••••',
              prefixIcon: Icons.lock_reset_outlined,
              obscureText: true,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.visiblePassword,
              validator: (value) =>
                  Validators.confirmPassword(value, passwordController.text),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TU CONTRASEÑA DEBE TENER',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Requirement(
                    label: '8 caracteres o más',
                    met: hasMinLength,
                  ),
                  _Requirement(label: 'Al menos un número', met: hasNumber),
                  _Requirement(label: 'Al menos un símbolo', met: hasSymbol),
                  _Requirement(
                    label: 'Ambas contraseñas coinciden',
                    met: matches,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _providerLabel(String? provider) {
    switch (provider?.toUpperCase()) {
      case 'APPLE':
        return 'Apple';
      case 'GOOGLE':
        return 'Google';
      default:
        return 'tu proveedor social';
    }
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: met ? AppColors.success : AppColors.textDisabled,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: met ? FontWeight.w700 : FontWeight.w500,
                color: met ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
