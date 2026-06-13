import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/onboarding_slide.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/ken_burns_background.dart';
import '../widgets/onboarding_dots.dart';
import '../widgets/onboarding_slide_view.dart';

/// Página principal del flujo de onboarding.
/// Muestra fondos animados de pantalla completa con crossfade (Ken Burns),
/// textos informativos sobre puestos/mecánicos y controles flotantes.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late final PageController _pageController;

  static const _slides = OnboardingSlide.slides;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finishOnboarding() async {
    await ref.read(onboardingPageProvider.notifier).markAsSeen();
    if (mounted) {
      context.go(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(onboardingPageProvider);
    final isLast = currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Fondos con crossfade + Ken Burns ─────────────────────────────
          ...List.generate(_slides.length, (i) {
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 700),
              opacity: currentPage == i ? 1.0 : 0.0,
              child: KenBurnsBackground(
                imageUrl: _slides[i].imagePath,
                active: currentPage == i,
              ),
            );
          }),

          // ── Scrim: degradado inferior para legibilidad del texto ─────────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.30, 0.55, 0.85, 1.0],
                colors: [
                  Color(0x400A0A0C),
                  Color(0x000A0A0C),
                  Color(0x260A0A0C),
                  Color(0xD10A0A0C),
                  Color(0xEB0A0A0C),
                ],
              ),
            ),
            child: SizedBox.expand(),
          ),

          // ── PageView transparente: captura gestos y dibuja textos ───────
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (page) {
              ref.read(onboardingPageProvider.notifier).setPage(page);
            },
            itemBuilder: (context, i) {
              return OnboardingSlideView(slide: _slides[i]);
            },
          ),

          // ── Header: Logo "GuIA" + Saltar ──────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(text: 'Gu'),
                        TextSpan(
                          text: 'IA',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    TextButton(
                      onPressed: () => _goTo(_slides.length - 1),
                      child: const Text(
                        'SALTAR',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Footer: Puntos kineticos + CTA / Swipe Hint ───────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OnboardingDots(
                      count: _slides.length,
                      currentIndex: currentPage,
                      onTap: _goTo,
                    ),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: isLast
                          ? Padding(
                              key: const ValueKey('cta'),
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                  ),
                                  onPressed: _finishOnboarding,
                                  child: const Text(
                                    'Comenzar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const Column(
                              key: ValueKey('hint'),
                              children: [
                                Text(
                                  'DESLIZA PARA CONTINUAR',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                    letterSpacing: 2,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Icon(
                                  Icons.swipe_left_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
