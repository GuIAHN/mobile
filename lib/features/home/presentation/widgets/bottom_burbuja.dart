import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/home_providers.dart';

/// Barra de navegación flotante tipo "burbuja" con glassmorphism.
/// El tab activo se expande en pill con label (icono + texto = mejor
/// descubribilidad que icono solo), con haptics y semántica de tab.
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_tabs.length, (index) {
                    final tab = _tabs[index];
                    final isSelected = index == activeTab;

                    return Semantics(
                      selected: isSelected,
                      button: true,
                      label: tab.label,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (index != activeTab) {
                            HapticFeedback.selectionClick();
                            ref.read(homeTabProvider.notifier).state = index;
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          height: 46,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSelected ? 16 : 11,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected ? tab.filled : tab.outline,
                                size: 22,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                              // El label solo ocupa espacio en el tab activo
                              AnimatedSize(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                                child: isSelected
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.only(left: 7),
                                        child: Text(
                                          tab.label,
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
