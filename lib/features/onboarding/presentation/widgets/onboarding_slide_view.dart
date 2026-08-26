import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/onboarding_slide.dart';

/// Widget que renderiza el contenido de texto centrado para cada slide del onboarding.
/// Diseñado para superponerse sobre el fondo oscuro de pantalla completa.
class OnboardingSlideView extends StatelessWidget {
  final OnboardingSlide slide;

  const OnboardingSlideView({super.key, required this.slide});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const topClearance = 88.0;
        // El footer se desplaza sobre la barra de gestos o de tres botones de
        // Android. Reservamos el mismo inset para que el texto nunca quede
        // oculto detrás de los controles del onboarding.
        final footerClearance =
            150.0 + MediaQuery.viewPaddingOf(context).bottom;
        final availableContentHeight =
            constraints.maxHeight - topClearance - footerClearance;

        return SingleChildScrollView(
          reverse: true,
          padding: EdgeInsets.fromLTRB(
            32,
            topClearance,
            32,
            footerClearance,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  availableContentHeight > 0 ? availableContentHeight : 0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  slide.tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primaryMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  slide.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
