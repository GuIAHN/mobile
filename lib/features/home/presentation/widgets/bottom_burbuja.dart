import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/home_providers.dart';

/// Barra de navegación flotante tipo "burbuja de agua / líquida" con glassmorphism.
/// El fondo líquido de la sección activa se transfiere con una animación fluida
/// y elástica (efecto gota de agua) entre tabs.
class BottomBurbuja extends ConsumerWidget {
  const BottomBurbuja({super.key});

  static const _tabs = [
    (
      outline: Icons.home_outlined,
      filled: Icons.home_rounded,
      label: 'Inicio',
    ),
    (
      outline: Icons.chat_bubble_outline_rounded,
      filled: Icons.chat_bubble_rounded,
      label: 'Chats',
    ),
    (
      outline: Icons.person_outline_rounded,
      filled: Icons.person_rounded,
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(homeTabProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Center(
          child: _LiquidBubbleNav(
            tabs: _tabs,
            activeTab: activeTab,
            onTabSelected: (index) {
              HapticFeedback.selectionClick();
              ref.read(homeTabProvider.notifier).state = index;
            },
          ),
        ),
      ),
    );
  }
}

class _LiquidBubbleNav extends StatefulWidget {
  final List<({IconData outline, IconData filled, String label})> tabs;
  final int activeTab;
  final ValueChanged<int> onTabSelected;

  const _LiquidBubbleNav({
    required this.tabs,
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  State<_LiquidBubbleNav> createState() => _LiquidBubbleNavState();
}

class _LiquidBubbleNavState extends State<_LiquidBubbleNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _stretchController;
  late Animation<double> _stretchXAnimation;
  late Animation<double> _stretchYAnimation;

  @override
  void initState() {
    super.initState();
    _stretchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _stretchXAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_stretchController);

    _stretchYAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_stretchController);
  }

  @override
  void didUpdateWidget(covariant _LiquidBubbleNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeTab != widget.activeTab) {
      _stretchController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _stretchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calcula la posición horizontal (-1.0 a 1.0) de la burbuja activa
    final double alignX =
        -1.0 + (widget.activeTab * (2.0 / (widget.tabs.length - 1)));

    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 250,
          height: 58,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 1. Fondo de agua / burbuja que se transfiere fluido elásticamente
              AnimatedAlign(
                duration: const Duration(milliseconds: 380),
                curve: Curves.fastOutSlowIn,
                alignment: Alignment(alignX, 0.0),
                child: FractionallySizedBox(
                  widthFactor: 1 / widget.tabs.length,
                  heightFactor: 1.0,
                  child: AnimatedBuilder(
                    animation: _stretchController,
                    builder: (context, child) {
                      return Transform.scale(
                        scaleX: _stretchXAnimation.value,
                        scaleY: _stretchYAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.45),
                            blurRadius: 14,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Capa interactiva con Íconos y Nombres de Sección (Nombre abajo del icono)
              Row(
                children: List.generate(widget.tabs.length, (index) {
                  final tab = widget.tabs[index];
                  final isSelected = index == widget.activeTab;

                  return Expanded(
                    child: Semantics(
                      selected: isSelected,
                      button: true,
                      label: tab.label,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (index != widget.activeTab) {
                            widget.onTabSelected(index);
                          }
                        },
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                                child: Icon(
                                  isSelected ? tab.filled : tab.outline,
                                  key: ValueKey('${tab.label}_$isSelected'),
                                  size: 20,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 220),
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  letterSpacing: 0.2,
                                ),
                                child: Text(tab.label),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
