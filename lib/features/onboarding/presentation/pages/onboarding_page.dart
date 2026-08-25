import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
    if (MediaQuery.of(context).disableAnimations) {
      _pageController.jumpToPage(index);
      return;
    }
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Fondos con crossfade + Ken Burns ─────────────────────────────
          ...List.generate(_slides.length, (i) {
            return AnimatedOpacity(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 700),
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          'assets/images/logo.png',
                          key: const Key('onboarding-brand-logo'),
                          width: 132,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          semanticLabel: 'guIAutomotriz HN',
                          errorBuilder: (context, error, stackTrace) {
                            return const Text(
                              'guIAutomotriz HN',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
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
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 350),
                      child: isLast
                          ? TextButton(
                              key: const Key('onboarding-continue'),
                              onPressed: _finishOnboarding,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 48),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                'Continuar',
                                textAlign: TextAlign.center,
                                style: AppTypography.label.copyWith(
                                  color: Colors.white,
                                  letterSpacing: 0.8,
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
