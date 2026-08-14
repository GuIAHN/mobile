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
const double _kActiveStageSize = 48;
const double _kNavLabelFontSize = 11;
const Duration _kAnimationDuration = Duration(milliseconds: 300);

/// Espacio superior donde el logo central y la muesca activa se integran con la cápsula.
const double kBottomNavOverhang = 18;

/// Alto base del área táctil de la cápsula.
const double kBottomNavBarHeight = 72;

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
          height: contentHeight + kBottomNavOverhang,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              const int totalSlots = 5;
              final slotWidth = totalWidth / totalSlots;

              // Coordenada X del centro del tab activo
              double getTabCenterX(int tab) {
                if (tab == 0) return slotWidth * 0.5; // Slot 0: Inicio
                if (tab == 1) return slotWidth * 1.5; // Slot 1: Chats
                if (!isStore && tab == 2) return slotWidth * 3.5; // Slot 3: Compras
                if (tab == perfilIndex) return slotWidth * 4.5; // Slot 4: Perfil
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
                    return isStore ? Icons.person_rounded : Icons.shopping_bag_rounded;
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
                            // Slot 2: Espacio del Logo Central
                            SizedBox(width: slotWidth),
                            // Slot 3: Compras (si es consumidor)
                            SizedBox(
                              width: slotWidth,
                              child: !isStore
                                  ? _NavItemSlot(
                                      outline: Icons.shopping_bag_outlined,
                                      label: 'Compras',
                                      isSelected: activeTab == 2,
                                      onTap: () => selectTab(2),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            // Slot 4: Perfil
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
    final notchLeft = (activeX - notchHalfWidth).clamp(cornerRadius, size.width - cornerRadius);
    final notchRight = (activeX + notchHalfWidth).clamp(cornerRadius, size.width - cornerRadius);

    if (notchLeft > cornerRadius) {
      path.lineTo(notchLeft, topY);
    }

    // Curva Bézier continua y suave de la muesca activa
    path.cubicTo(
      activeX - 26, topY,
      activeX - 18, notchPeakY,
      activeX, notchPeakY,
    );
    path.cubicTo(
      activeX + 18, notchPeakY,
      activeX + 26, topY,
      notchRight, topY,
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

    // Sombra suave inferior estilo card flotante
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path.shift(const Offset(0, 6)), shadowPaint);

    // Relleno de la superficie
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Borde sutil exterior
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
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
          child: Icon(
            icon,
            key: ValueKey<IconData>(icon),
            size: 24,
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
                  child: Icon(
                    widget.outline,
                    size: 22,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: _kNavLabelFontSize,
                    fontWeight: widget.isSelected
                        ? FontWeight.w800
                        : FontWeight.w600,
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
      label: 'Volver al inicio, logo guIAutomotriz',
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 90),
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

