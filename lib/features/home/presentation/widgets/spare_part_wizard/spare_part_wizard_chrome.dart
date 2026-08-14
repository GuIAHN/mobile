part of 'spare_part_wizard_page.dart';

class _WizardHeader extends StatelessWidget {
  final int step;
  final VoidCallback onBack;

  const _WizardHeader({
    required this.step,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Vehículo', 'Repuesto', 'Detalles'];

    return Semantics(
      container: true,
      label: 'Paso $step de 3, ${labels[step - 1]}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 24, 10),
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    tooltip: 'Volver',
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Paso $step de 3 · ${labels[step - 1]}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _WizardProgress(step: step),
          ],
        ),
      ),
    );
  }
}

class _WizardProgress extends StatelessWidget {
  final int step;

  const _WizardProgress({required this.step});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Row(
      children: List.generate(3, (index) {
        final active = index < step;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
            child: AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              height: 4,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.grey200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _WizardBottomBar extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onPressed;

  const _WizardBottomBar({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.errorMessage,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (errorMessage != null) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.errorInk,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeightLg,
              child: ElevatedButton(
                onPressed: enabled && !loading ? onPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.disabledBackground,
                  disabledForegroundColor: AppColors.textDisabled,
                  elevation: enabled ? 4 : 0,
                  shadowColor: AppColors.primary.withValues(alpha: 0.28),
                  shape: const StadiumBorder(),
                ),
                child: AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  child: loading
                      ? const SizedBox(
                          key: ValueKey('wizard-submit-loading'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          label,
                          key: ValueKey(label),
                          style: AppTypography.label.copyWith(
                            fontSize: 15,
                            letterSpacing: 0.4,
                            color:
                                enabled ? Colors.white : AppColors.textDisabled,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
