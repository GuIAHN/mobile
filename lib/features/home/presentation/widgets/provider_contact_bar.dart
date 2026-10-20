import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_decorations.dart';

class ProviderContactBar extends StatelessWidget {
  final String phone;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const ProviderContactBar({
    super.key,
    required this.phone,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final useVerticalLayout =
        MediaQuery.textScalerOf(context).scale(1) >= 1.6 ||
            MediaQuery.sizeOf(context).width < 340;
    final call = _ContactButton(
      key: const Key('service-provider-call'),
      icon: AppIcons.call,
      label: 'Llamar',
      semanticsLabel: 'Llamar al $phone',
      onPressed: onCall,
      primary: false,
    );
    final whatsapp = _ContactButton(
      key: const Key('service-provider-whatsapp'),
      icon: AppIcons.message,
      label: 'WhatsApp',
      semanticsLabel: 'Escribir por WhatsApp al $phone',
      onPressed: onWhatsApp,
      primary: true,
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        key: const Key('service-provider-contact-bar'),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: AppDecorations.raised,
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: useVerticalLayout
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    call,
                    const SizedBox(height: AppSpacing.sm),
                    whatsapp,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: call),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: whatsapp),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String semanticsLabel;
  final VoidCallback onPressed;
  final bool primary;

  const _ContactButton({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.onPressed,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLineIcon(icon, size: AppIconSize.action),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              color: primary ? AppColors.textOnPrimary : AppColors.primaryInk,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: SizedBox(
        width: double.infinity,
        height: AppSpacing.buttonHeightLg,
        child: primary
            ? ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
                child: child,
              )
            : OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryInk,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
                child: child,
              ),
      ),
    );
  }
}
