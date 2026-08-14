import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/providers/current_user_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/home_providers.dart';

const double _kLogoSize = 56;
const double _kHorizontalMargin = 14;
const double _kBottomMargin = 8;
const double _kActivePillWidth = 52;
const double _kActivePillHeight = 30;
const double _kNavLabelFontSize = 11;
const Duration _kAnimationDuration = Duration(milliseconds: 240);

/// Espacio superior reservado para integrar el logo central del consumidor.
const double kBottomNavOverhang = 18;

/// Alto base del área táctil de la cápsula.
const double kBottomNavBarHeight = 60;

/// Padding inferior que deben reservar las vistas que extienden su contenido.
double bottomNavContentInset(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final scaledLabelHeight = mediaQuery.textScaler.scale(_kNavLabelFontSize);
  final labelGrowth = (scaledLabelHeight - _kNavLabelFontSize).clamp(
    0.0,
    double.infinity,
  );

  return kBottomNavBarHeight +
      labelGrowth +
      mediaQuery.padding.bottom +
      _kBottomMargin;
}

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(homeTabProvider);
    final isStore = ref.watch(currentRoleProvider).isStore;
    final mediaQuery = MediaQuery.of(context);
    final scaledLabelHeight = mediaQuery.textScaler.scale(_kNavLabelFontSize);
    final labelGrowth = (scaledLabelHeight - _kNavLabelFontSize).clamp(
      0.0,
      double.infinity,
    );
    final contentHeight = kBottomNavBarHeight + labelGrowth;
    final perfilIndex = isStore ? 2 : 3;
    final surfaceTop = isStore ? 0.0 : kBottomNavOverhang;

    void selectTab(int index) {
      if (index == activeTab) return;
      HapticFeedback.selectionClick();
      ref.read(homeTabProvider.notifier).state = index;
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: _kHorizontalMargin,
        right: _kHorizontalMargin,
        bottom: _kBottomMargin,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: contentHeight + surfaceTop,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final totalSlots = isStore ? 3 : 5;
              final slotWidth = totalWidth / totalSlots;

              // Coordenada X del centro del tab activo
              double getTabCenterX(int tab) {
                if (isStore) {
                  return slotWidth * (tab.clamp(0, 2) + 0.5);
                }
                if (tab == 0) return slotWidth * 0.5; // Slot 0: Inicio
                if (tab == 1) return slotWidth * 1.5; // Slot 1: Chats
                if (tab == 2) return slotWidth * 3.5; // Slot 3: Compras
                if (tab == perfilIndex) {
                  return slotWidth * 4.5; // Slot 4: Perfil
                }
                return slotWidth * 0.5;
              }

              final targetX = getTabCenterX(activeTab);

              // Ícono para la etapa activa según tab seleccionado
              IconData getActiveIcon(int tab) {
                switch (tab) {
                  case 0:
                    return Icons.home_rounded;
                  case 1:
                    return Icons.chat_bubble_rounded;
                  case 2:
                    return isStore
                        ? Icons.person_rounded
                        : Icons.shopping_bag_rounded;
                  case 3:
                    return Icons.person_rounded;
                  default:
                    return Icons.home_rounded;
                }
              }

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: targetX, end: targetX),
                duration: mediaQuery.disableAnimations
                    ? Duration.zero
                    : _kAnimationDuration,
                curve: Curves.easeOutCubic,
                builder: (context, currentX, child) {
                  return Stack(
                    alignment: Alignment.topLeft,
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Superficie estable: la selección no modifica su
                      // forma ni proyecta una sombra móvil.
                      Positioned(
                        top: surfaceTop,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: DecoratedBox(
                          key: const Key('bottom-nav-surface'),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Fila de items inactivos/etiquetas en slots fijos
                      Positioned(
                        top: surfaceTop,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Row(
                          children: [
                            // Slot 0: Inicio
                            SizedBox(
                              width: slotWidth,
                              child: _NavItemSlot(
                                outline: Icons.home_outlined,
                                label: 'Inicio',
                                isSelected: activeTab == 0,
                                onTap: () => selectTab(0),
                              ),
                            ),
                            // Slot 1: Chats
                            SizedBox(
                              width: slotWidth,
                              child: _NavItemSlot(
                                outline: Icons.chat_bubble_outline_rounded,
                                label: 'Chats',
                                isSelected: activeTab == 1,
                                onTap: () => selectTab(1),
                              ),
                            ),
                            if (!isStore) ...[
                              // Slot 2: Espacio del Logo Central
                              SizedBox(width: slotWidth),
                              // Slot 3: Compras
                              SizedBox(
                                width: slotWidth,
                                child: _NavItemSlot(
                                  outline: Icons.shopping_bag_outlined,
                                  label: 'Compras',
                                  isSelected: activeTab == 2,
                                  onTap: () => selectTab(2),
                                ),
                              ),
                            ],
                            // Slot 2 para tienda; slot 4 para consumidor.
                            SizedBox(
                              width: slotWidth,
                              child: _NavItemSlot(
                                outline: Icons.person_outline_rounded,
                                label: 'Perfil',
                                isSelected: activeTab == perfilIndex,
                                onTap: () => selectTab(perfilIndex),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 3. Pill plana que solo se desplaza horizontalmente.
                      Positioned(
                        top: surfaceTop + 9,
                        left: currentX - (_kActivePillWidth / 2),
                        child: _SlidingActivePill(
                          key: const Key('bottom-nav-active-pill'),
                          icon: getActiveIcon(activeTab),
                        ),
                      ),

                      // 4. El logo es una acción exclusiva del consumidor.
                      if (!isStore)
                        Positioned(
                          top: 0,
                          left: (totalWidth / 2) - (_kLogoSize / 2),
                          child: _CenterLogoButton(
                            isSelected: activeTab == 0,
                            onTap: () => selectTab(0),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Indicador activo contenido dentro de la barra, sin elevación ni sombra.
class _SlidingActivePill extends StatelessWidget {
  final IconData icon;

  const _SlidingActivePill({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return SizedBox(
      width: _kActivePillWidth,
      height: _kActivePillHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primaryMuted,
          borderRadius: BorderRadius.circular(_kActivePillHeight / 2),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.18),
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Icon(
              icon,
              key: ValueKey<IconData>(icon),
              size: 24,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Slot individual para íconos inactivos y etiquetas de navegación.
class _NavItemSlot extends StatefulWidget {
  final IconData outline;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemSlot({
    required this.outline,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItemSlot> createState() => _NavItemSlotState();
}

class _NavItemSlotState extends State<_NavItemSlot> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      selected: widget.isSelected,
      button: true,
      label: widget.label,
      onTap: widget.onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          excludeFromSemantics: true,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          onHighlightChanged: _setPressed,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.94 : 1.0,
            duration:
                reduceMotion ? Duration.zero : const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 6),
                AnimatedOpacity(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  opacity: widget.isSelected ? 0.0 : 1.0,
                  child: Icon(
                    widget.outline,
                    size: 22,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: _kNavLabelFontSize,
                    fontWeight:
                        widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: widget.isSelected
                        ? AppColors.primary
                        : AppColors.grey600,
                    letterSpacing: 0.1,
                  ),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo de la marca al centro de la barra totalmente integrado.
class _CenterLogoButton extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _CenterLogoButton({
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CenterLogoButton> createState() => _CenterLogoButtonState();
}

class _CenterLogoButtonState extends State<_CenterLogoButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      container: true,
      excludeSemantics: true,
      selected: widget.isSelected,
      button: true,
      label: 'Volver al inicio, logo guIAutomotriz',
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: SizedBox.square(
          dimension: _kLogoSize,
          child: Material(
            color: AppColors.surface,
            shape: CircleBorder(
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.28),
                width: 1.5,
              ),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
            child: InkResponse(
              containedInkWell: true,
              customBorder: const CircleBorder(),
              excludeFromSemantics: true,
              onHighlightChanged: _setPressed,
              onTap: widget.onTap,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      blurRadius: 14,
                      spreadRadius: -2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo_icon_zoom.png',
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stackTrace) {
                        return const ColoredBox(
                          color: AppColors.primaryMuted,
                          child: Icon(
                            Icons.home_rounded,
                            size: 26,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
