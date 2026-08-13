import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/providers/current_user_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/home_providers.dart';

/// Tamaño del logo central integrado.
const double _kLogoSize = 52;

/// Desplaza el logo ligeramente para encajar en la barra.
const double _kLogoTopOffset = 4;

/// Sobresaliente mínimo del logo.
const double kBottomNavOverhang = 12;

/// Alto de la franja base de la barra.
const double kBottomNavBarHeight = 62;

const double _kNavLabelFontSize = 11;

/// Padding inferior que deben reservar las vistas.
double bottomNavContentInset(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final scaledLabelHeight = mediaQuery.textScaler.scale(_kNavLabelFontSize);
  final labelGrowth = (scaledLabelHeight - _kNavLabelFontSize).clamp(
    0.0,
    double.infinity,
  );

  return kBottomNavBarHeight + labelGrowth + mediaQuery.padding.bottom;
}

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(homeTabProvider);
    final isStore = ref.watch(currentRoleProvider).isStore;

    void selectTab(int index) {
      if (index == activeTab) return;
      HapticFeedback.selectionClick();
      ref.read(homeTabProvider.notifier).state = index;
    }

    final perfilIndex = isStore ? 2 : 3;

    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // ── Barra base integrada ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(
            top: kBottomNavOverhang,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 6),
                child: Row(
                  children: [
                    // ── Lado izquierdo ─────────────────────────────────────
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

                    // ── Hueco integrado para el logo ───────────────────────
                    const SizedBox(width: _kLogoSize + 12),

                    // ── Lado derecho ───────────────────────────────────────
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

        // ── Logo central integrado ───────────────────────────────────────────
        Positioned(
          top: _kLogoTopOffset,
          child: _CenterLogoButton(
            isSelected: activeTab == 0,
            onTap: () => selectTab(0),
          ),
        ),
      ],
    );
  }
}

/// Logo de la marca al centro de la barra totalmente integrado.
class _CenterLogoButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _CenterLogoButton({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      container: true,
      excludeSemantics: true,
      selected: isSelected,
      button: true,
      label: 'Volver al inicio, logo guIAutomotriz',
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkResponse(
          containedInkWell: true,
          customBorder: const CircleBorder(),
          excludeFromSemantics: true,
          onTap: onTap,
          child: AnimatedScale(
            scale: isSelected ? 1.06 : 0.96,
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: _kLogoSize,
              height: _kLogoSize,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.grey300.withValues(alpha: 0.8),
                  width: isSelected ? 2.0 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.20)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: isSelected ? 10 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo_icon_zoom.png',
                  width: _kLogoSize - 8,
                  height: _kLogoSize - 8,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primaryMuted,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.home_rounded,
                        size: 24,
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
    );
  }
}

/// Elemento de navegación con pill indicador activo y animación suave.
class _NavItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        container: true,
        excludeSemantics: true,
        selected: isSelected,
        button: true,
        label: label,
        onTap: onTap,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          excludeFromSemantics: true,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pill indicador animado para el ícono activo
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryMuted.withValues(alpha: 0.90)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.20)
                          : Colors.transparent,
                      width: 1.0,
                    ),
                  ),
                  child: AnimatedScale(
                    scale: isSelected ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      isSelected ? filled : outline,
                      size: 21,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.grey600,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: _kNavLabelFontSize,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.grey600,
                    letterSpacing: 0.1,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
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
