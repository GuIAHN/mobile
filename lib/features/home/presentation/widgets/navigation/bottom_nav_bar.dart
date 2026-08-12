import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/providers/current_user_provider.dart';
import '../../providers/home_providers.dart';

/// Tamaño del logo central.
const double _kLogoSize = 64;

/// Elevación adicional respecto al mockup anterior.
const double _kLogoLift = 12;

/// Cuánto sobresale el logo por encima de la barra.
/// Esta franja es transparente: el contenido de la app se ve continuo detrás.
const double kBottomNavOverhang = 30;

/// Alto de la franja blanca de la barra (iconos + etiquetas + padding),
/// sin contar el área segura inferior ni el overhang del logo.
const double kBottomNavBarHeight = 58;

/// Padding inferior que deben reservar las vistas para no quedar tapadas
/// por la barra cuando el Scaffold usa `extendBody: true`.
double bottomNavContentInset(BuildContext context) =>
    kBottomNavBarHeight + MediaQuery.of(context).padding.bottom;

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
        // ── Barra ────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: kBottomNavOverhang),
          child: Material(
            // Solo la barra tiene fondo. La franja superior (overhang) queda
            // transparente para que el contenido de la app se vea continuo
            // detrás de la parte saliente del logo.
            color: AppColors.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
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

                    // ── Hueco para el logo central ─────────────────────────
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
                    // Mantiene el logo centrado cuando hay 3 tabs (tienda).
                    if (isStore) const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Logo central sobresaliente ───────────────────────────────────────
        Positioned(
          top: -_kLogoLift,
          child: _CenterLogoButton(
            isSelected: activeTab == 0,
            onTap: () => selectTab(0),
          ),
        ),
      ],
    );
  }
}

/// Logo de la marca al centro de la barra. Lleva al Home.
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
          child: SizedBox.square(
            dimension: _kLogoSize,
            child: AnimatedScale(
              scale: reduceMotion ? 1 : (isSelected ? 1.0 : 0.92),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Image.asset(
                'assets/images/logo_icon.png',
                width: _kLogoSize,
                height: _kLogoSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
          excludeFromSemantics: true,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? filled : outline,
                  size: 24,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    letterSpacing: 0.2,
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
