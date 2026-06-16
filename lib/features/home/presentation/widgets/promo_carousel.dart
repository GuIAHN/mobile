import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/promo.dart';
import 'icon_mapper.dart';

class PromoCarousel extends StatefulWidget {
  final List<Promo> promos;

  const PromoCarousel({super.key, required this.promos});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final _pageController = PageController();
  int _currentIndex = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(PromoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.promos != widget.promos && _pageController.hasClients) {
      _pageController.jumpToPage(0);
      setState(() => _currentIndex = 0);
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.promos.length <= 1) return;
    
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) return;
      final nextPage = (_currentIndex + 1) % widget.promos.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.promos.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.promos.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return _BannerCard(promo: widget.promos[index]);
            },
          ),
        ),
        // Indicadores tipo líneas horizontales superpuestos en la esquina inferior izquierda
        Positioned(
          left: 24, // Alineado con el padding de texto interior de la card (que tiene horizontal: 4 padding de PageView + 20 de la card)
          bottom: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.promos.length, (index) {
              final isSelected = index == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 6),
                width: isSelected ? 28 : 14,
                height: 3,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final Promo promo;

  const _BannerCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    final colors = promo.gradientColors.map((hex) => Color(hex)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4), // Separación entre tarjetas en PageView
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. Imagen de fondo (si está disponible)
            if (promo.imageUrl != null)
              Positioned.fill(
                child: Image.network(
                  promo.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors.isNotEmpty ? colors : [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.grey100,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors.isNotEmpty ? colors : [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

            // 2. Capa de overlay degradado oscuro (del 80% al 20%) para legibilidad impecable
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
            ),

            // 3. Formas geométricas abstractas para profundidad visual
            Positioned(
              right: -30,
              top: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // 4. Icono de marca difuminado en la parte derecha
            Positioned(
              right: AppSpacing.xl,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  getIconData(promo.iconName),
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),

            // 5. Contenido textual
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 110, 36), // Más espacio abajo para los indicadores de línea
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FEATURED SERVICE',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      promo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    if (promo.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        promo.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
