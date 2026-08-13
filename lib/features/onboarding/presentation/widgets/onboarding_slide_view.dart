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
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        // Deja espacio libre en la parte inferior para los puntos (dots) y botones del footer.
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 150),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
  }
}
