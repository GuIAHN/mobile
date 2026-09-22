import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/current_user_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../shared/layout/bottom_navigation_insets.dart';
import '../../providers/home_providers.dart';

const double _kLogoSize = 56;
const double _kHorizontalMargin = 14;
const double _kActiveStageSize = 48;
const double _kNavLabelFontSize = bottomNavigationLabelFontSize;
const Duration _kAnimationDuration = Duration(milliseconds: 300);

/// Espacio superior donde el logo central y la muesca activa se integran con la cápsula.
const double kBottomNavOverhang = 18;

/// Alto base del área táctil de la cápsula.
const double kBottomNavBarHeight = bottomNavigationBarHeight;

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

    void selectTab(MainNavigationTab tab) {
      if (tab == activeTab) return;
      HapticFeedback.selectionClick();
      ref.read(homeTabProvider.notifier).state = tab;
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: _kHorizontalMargin,
        right: _kHorizontalMargin,
        bottom: bottomNavigationBottomMargin,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: contentHeight + kBottomNavOverhang,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              const int totalSlots = 5;
              final slotWidth = totalWidth / totalSlots;

              // Coordenada X del centro del tab activo
              double getTabCenterX(MainNavigationTab tab) {
                switch (tab) {
                  case MainNavigationTab.home:
                    return slotWidth * 0.5;
                  case MainNavigationTab.purchases:
                    return slotWidth * 1.5;
                  case MainNavigationTab.requests:
                    return slotWidth * 3.5;
                  case MainNavigationTab.profile:
                    return slotWidth * 4.5;
                }
              }

              final targetX = getTabCenterX(activeTab);

              // Ícono para la etapa activa según tab seleccionado
              IconData getActiveIcon(MainNavigationTab tab) {
                switch (tab) {
                  case MainNavigationTab.home:
                    return AppIcons.home;
                  case MainNavigationTab.purchases:
                    return isStore ? AppIcons.sales : AppIcons.purchases;
                  case MainNavigationTab.requests:
                    return AppIcons.requests;
                  case MainNavigationTab.profile:
                    return AppIcons.account;
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
                      // 1. Fondo de cápsula pintado con muesca suave animada
                      Positioned(
                        top: kBottomNavOverhang,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: CustomPaint(
                          key: const Key('bottom-nav-surface'),
                          painter: _NotchCapsulePainter(
                            activeX: currentX,
                            color: AppColors.surface,
                            borderColor: AppColors.border,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),

                      // 2. Fila de items inactivos/etiquetas en slots fijos
                      Positioned(
                        top: kBottomNavOverhang,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Row(
                          children: [
                            // Slot 0: Inicio
                            SizedBox(
                              width: slotWidth,
                              child: _NavItemSlot(
                                outline: AppIcons.home,
                                label: 'Inicio',
                                isSelected: activeTab == MainNavigationTab.home,
                                onTap: () => selectTab(MainNavigationTab.home),
                              ),
                            ),
                            // Slot 1: Mis ventas para tienda, Compras para consumidor
                            SizedBox(
                              width: slotWidth,
                              child: _NavItemSlot(
                                outline: isStore
                                    ? AppIcons.sales
                                    : AppIcons.purchases,
                                label: isStore ? 'Mis ventas' : 'Compras',
                                isSelected:
                                    activeTab == MainNavigationTab.purchases,
                                onTap: () =>
                                    selectTab(MainNavigationTab.purchases),
                              ),
                            ),
                            // Slot 2: Espacio del Logo Central
                            SizedBox(width: slotWidth),
                            // Slot 3: Solicitudes para tienda y consumidor
                            SizedBox(
                              width: slotWidth,
                              child: _NavItemSlot(
                                outline: AppIcons.requests,
                                label: 'Solicitudes',
                                isSelected:
                                    activeTab == MainNavigationTab.requests,
                                onTap: () =>
                                    selectTab(MainNavigationTab.requests),
                              ),
                            ),
                            // Slot 4: Perfil
                            SizedBox(
                              width: slotWidth,
                              child: _NavItemSlot(
                                outline: AppIcons.account,
                                label: 'Perfil',
                                isSelected:
                                    activeTab == MainNavigationTab.profile,
                                onTap: () =>
                                    selectTab(MainNavigationTab.profile),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 3. Círculo elevable activo deslizante
                      Positioned(
                        top: 2,
                        left: currentX - (_kActiveStageSize / 2),
                        child: _ActiveIndicatorStage(
                          icon: getActiveIcon(activeTab),
                        ),
                      ),

                      // 4. Logo central mantenido en el medio
                      Positioned(
                        top: 0,
                        left: (totalWidth / 2) - (_kLogoSize / 2),
                        child: _CenterLogoButton(
                          isSelected: activeTab == MainNavigationTab.home,
                          onTap: () => selectTab(MainNavigationTab.home),
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

/// Painter personalizado que dibuja la cápsula flotante con una muesca curva orgánica
/// elevada que se desliza suavemente sobre la pestaña activa.
class _NotchCapsulePainter extends CustomPainter {
  final double activeX;
  final Color color;
  final Color borderColor;

  _NotchCapsulePainter({
    required this.activeX,
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double topY = 14.0;
    final double bottomY = size.height;
    const double cornerRadius = 26.0;
    const double notchHalfWidth = 42.0;
    const double notchPeakY = 0.0;

    final path = Path();

    // Esquina superior izquierda
    path.moveTo(0, topY + cornerRadius);
    path.arcToPoint(
      const Offset(cornerRadius, topY),
      radius: const Radius.circular(cornerRadius),
    );

    // Borde superior izquierdo hasta el inicio de la muesca
    final notchLeft = (activeX - notchHalfWidth)
        .clamp(cornerRadius, size.width - cornerRadius);
    final notchRight = (activeX + notchHalfWidth)
        .clamp(cornerRadius, size.width - cornerRadius);

    if (notchLeft > cornerRadius) {
      path.lineTo(notchLeft, topY);
    }

    // Curva Bézier continua y suave de la muesca activa
    path.cubicTo(
      activeX - 26,
      topY,
      activeX - 18,
      notchPeakY,
      activeX,
      notchPeakY,
    );
    path.cubicTo(
      activeX + 18,
      notchPeakY,
      activeX + 26,
      topY,
      notchRight,
      topY,
    );

    // Borde superior derecho desde el final de la muesca
    if (notchRight < size.width - cornerRadius) {
      path.lineTo(size.width - cornerRadius, topY);
    }

    // Esquina superior derecha
    path.arcToPoint(
      Offset(size.width, topY + cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );

    // Lateral derecho
    path.lineTo(size.width, bottomY - cornerRadius);

    // Esquina inferior derecha
    path.arcToPoint(
      Offset(size.width - cornerRadius, bottomY),
      radius: const Radius.circular(cornerRadius),
    );

    // Borde inferior
    path.lineTo(cornerRadius, bottomY);

    // Esquina inferior izquierda
    path.arcToPoint(
      Offset(0, bottomY - cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );

    // Lateral izquierdo
    path.close();

    // Relleno de la superficie: sin sombra ni borde para que la cápsula
    // se sienta fluida y continua con el contenido de la app detrás.
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _NotchCapsulePainter oldDelegate) {
    return oldDelegate.activeX != activeX ||
        oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor;
  }
}

/// Escenario circular flotante para el ícono de la pestaña activa.
class _ActiveIndicatorStage extends StatelessWidget {
  final IconData icon;

  const _ActiveIndicatorStage({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('bottom-nav-active-indicator'),
      width: _kActiveStageSize,
      height: _kActiveStageSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.28),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 12,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: AppLineIcon(
            icon,
            key: ValueKey<IconData>(icon),
            size: AppIconSize.leading,
            color: AppColors.primary,
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
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: widget.isSelected ? 0.0 : 1.0,
                  child: AppLineIcon(
                    widget.outline,
                    size: AppIconSize.action,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  style: AppTypography.meta.copyWith(
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

/// Botón central oficial con el logo guIAutomotriz, mantenido fijo en el medio.
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
      label: 'Volver al inicio, logo GuIA Automotriz HN',
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
            shape: const CircleBorder(),
            elevation: 0,
            shadowColor: Colors.transparent,
            child: InkResponse(
              containedInkWell: true,
              customBorder: const CircleBorder(),
              excludeFromSemantics: true,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              splashFactory: NoSplash.splashFactory,
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
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo_icon_zoom.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) {
                      return const ColoredBox(
                        color: AppColors.primaryMuted,
                        child: AppLineIcon(
                          AppIcons.home,
                          size: AppIconSize.leading,
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
    );
  }
}
