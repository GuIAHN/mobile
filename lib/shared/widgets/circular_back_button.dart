import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Un botón de retroceso circular premium utilizado en el flujo de registro y onboarding.
class CircularBackButton extends StatelessWidget {
  final VoidCallback onTap;
  final String tooltip;

  const CircularBackButton({
    super.key,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.loginSurface,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.loginOutlineVar),
        ),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.loginOnSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
