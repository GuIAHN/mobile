import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/providers/current_user_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/home_providers.dart';

const double _kLogoSize = 58;
const double _kHorizontalMargin = 14;
const double _kBottomMargin = 8;
const double _kActiveStageSize = 48;
const double _kActiveLift = 6;

/// Espacio superior donde el logo central se integra con la cápsula.
const double kBottomNavOverhang = 18;

/// Alto base del área táctil; crece con el escalado de texto.
const double kBottomNavBarHeight = 72;

const double _kNavLabelFontSize = 11;
const Duration _kSelectionDuration = Duration(milliseconds: 220);
const Duration _kPressDuration = Duration(milliseconds: 90);

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

    void selectTab(int index) {
      if (index == activeTab) return;
      HapticFeedback.selectionClick();
      ref.read(homeTabProvider.notifier).state = index;
    }

    final perfilIndex = isStore ? 2 : 3;

    return Padding(
      padding: const EdgeInsets.only(
        left: _kHorizontalMargin,
        right: _kHorizontalMargin,
        bottom: _kBottomMargin,
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: kBottomNavOverhang),
            child: DecoratedBox(
              key: const Key('bottom-nav-surface'),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 22,
                    spreadRadius: -3,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: contentHeight,
                    child: Row(
                      children: [
                        _NavItem(
                          outline: Icons.home_outlined,
                          filled: Icons.home_rounded,
                          label: 'Inicio',
                          isSelected: activeTab == 0,
                          onTap: () => selectTab(0),
                        ),
                        _NavItem(
                          outline: Icons.chat_bubble_outline_rounded,
                          filled: Icons.chat_bubble_rounded,
                          label: 'Chats',
                          isSelected: activeTab == 1,
                          onTap: () => selectTab(1),
                        ),
                        const SizedBox(width: _kLogoSize + 12),
                        if (!isStore)
                          _NavItem(
                            outline: Icons.shopping_bag_outlined,
                            filled: Icons.shopping_bag_rounded,
                            label: 'Compras',
                            isSelected: activeTab == 2,
                            onTap: () => selectTab(2),
                          ),
                        _NavItem(
                          outline: Icons.person_outline_rounded,
                          filled: Icons.person_rounded,
                          label: 'Perfil',
                          isSelected: activeTab == perfilIndex,
                          onTap: () => selectTab(perfilIndex),
                        ),
                        if (isStore) const Expanded(child: SizedBox.shrink()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: _CenterLogoButton(
              isSelected: activeTab == 0,
              onTap: () => selectTab(0),
            ),
          ),
        ],
      ),
    );
  }
}

/// Acción de inicio con el logo oficial, estable al cambiar de pestaña.
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
        scale: _isPressed ? 0.97 : 1,
        duration: reduceMotion ? Duration.zero : _kPressDuration,
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

/// Destino lateral con círculo activo elevado y feedback táctil discreto.
class _NavItem extends StatefulWidget {
  final IconData outline;
  final IconData filled;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.outline,
    required this.filled,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final selectionDuration =
        reduceMotion ? Duration.zero : _kSelectionDuration;
    final pressDuration = reduceMotion ? Duration.zero : _kPressDuration;

    return Expanded(
      child: Semantics(
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
            onHighlightChanged: _setPressed,
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _isPressed ? 0.97 : 1,
              duration: pressDuration,
              curve: Curves.easeOutCubic,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSlide(
                      offset: widget.isSelected
                          ? const Offset(0, -_kActiveLift / _kActiveStageSize)
                          : Offset.zero,
                      duration: selectionDuration,
                      curve: Curves.easeOutCubic,
                      child: AnimatedContainer(
                        key: Key('bottom-nav-icon-stage-${widget.label}'),
                        width: _kActiveStageSize,
                        height: _kActiveStageSize,
                        duration: selectionDuration,
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isSelected
                              ? AppColors.primaryMuted
                              : Colors.transparent,
                          border: Border.all(
                            color: widget.isSelected
                                ? AppColors.primary.withValues(alpha: 0.18)
                                : Colors.transparent,
                          ),
                          boxShadow: widget.isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    blurRadius: 12,
                                    spreadRadius: -4,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : const [],
                        ),
                        child: Icon(
                          widget.isSelected ? widget.filled : widget.outline,
                          size: 22,
                          color: widget.isSelected
                              ? AppColors.primary
                              : AppColors.grey600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedDefaultTextStyle(
                      duration: selectionDuration,
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
        ),
      ),
    );
  }
}
