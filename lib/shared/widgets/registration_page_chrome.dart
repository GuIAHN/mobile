import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Shared adaptive chrome for the registration flows.
///
/// These widgets intentionally react to available space and scaled text instead
/// of device brands or hard-coded phone models.
class RegistrationPageHeader extends StatelessWidget {
  const RegistrationPageHeader({
    super.key,
    required this.title,
    required this.onBack,
    required this.backTooltip,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final String backTooltip;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          tooltip: backTooltip,
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          padding: EdgeInsets.zero,
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Center(child: trailing),
          ),
        ],
      ],
    );
  }
}

class RegistrationStepProgress extends StatelessWidget {
  const RegistrationStepProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      'PASO $currentStep DE $totalSteps',
      style: GoogleFonts.hankenGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: AppColors.textSecondary,
      ),
    );
    final progress = Row(
      children: List.generate(totalSteps, (index) {
        return Expanded(
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 300),
            height: 5,
            margin: EdgeInsets.only(left: index == 0 ? 0 : 6),
            decoration: BoxDecoration(
              color: index < currentStep ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );

    final windowWidth = MediaQuery.sizeOf(context).width;
    final scaledLabelSize = MediaQuery.textScalerOf(context).scale(11);
    final stacks = windowWidth < 368 || scaledLabelSize >= 17;
    if (stacks) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          label,
          const SizedBox(height: 10),
          progress,
        ],
      );
    }
    return Row(
      children: [
        label,
        const SizedBox(width: 12),
        Expanded(child: progress),
      ],
    );
  }
}

class RegistrationActionLabel extends StatelessWidget {
  const RegistrationActionLabel({
    super.key,
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 18),
      ],
    );
  }
}

class RegistrationLoginLink extends StatelessWidget {
  const RegistrationLoginLink({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.hankenGrotesk(
      fontSize: 15,
      color: AppColors.textSecondary,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('¿Ya tienes una cuenta?', style: baseStyle),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            textStyle: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Inicia sesión'),
        ),
      ],
    );
  }
}

class RegistrationNavigationActions extends StatelessWidget {
  const RegistrationNavigationActions({
    super.key,
    required this.secondary,
    required this.primary,
  });

  final Widget secondary;
  final Widget primary;

  @override
  Widget build(BuildContext context) {
    final windowWidth = MediaQuery.sizeOf(context).width;
    final scaledButtonText = MediaQuery.textScalerOf(context).scale(14);
    final stacks = windowWidth < 348 || scaledButtonText >= 22;
    if (stacks) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          primary,
          const SizedBox(height: 12),
          secondary,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: secondary),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: primary),
      ],
    );
  }
}
