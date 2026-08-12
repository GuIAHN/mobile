import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/providers/current_user_provider.dart';
import '../../providers/home_providers.dart';

/// Barra de navegación inferior FIJA (estilo Mercado Libre / Pedidos Ya).
/// El tab central es el Home y usa el logo de la app en lugar de una casa.
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

    // La tienda no compra: no tiene sentido el tab "Mis Compras".
    final perfilIndex = isStore ? 2 : 3;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.grey200, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _LogoNavItem(
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
              if (!isStore)
                _NavItem(
                  outline: Icons.shopping_bag_outlined,
                  filled: Icons.shopping_bag_rounded,
                  label: 'Mis Compras',
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
            ],
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
        selected: isSelected,
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
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
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab central del Home: usa el logo de la app en lugar de un icono de casa.
class _LogoNavItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LogoNavItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.4,
                child: Image.asset(
                  'assets/images/logo_icon.png',
                  height: 42,
                  width: 42,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.home_rounded,
                      size: 24,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    );
                  },
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
