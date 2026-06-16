import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/home_providers.dart';

class BottomBurbuja extends ConsumerWidget {
  const BottomBurbuja({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(homeTabProvider);

    final List<IconData> outlineIcons = [
      Icons.home_outlined,
      Icons.chat_bubble_outline_rounded,
      Icons.person_outline_rounded,
    ];

    final List<IconData> filledIcons = [
      Icons.home_rounded,
      Icons.chat_bubble_rounded,
      Icons.person_rounded,
    ];

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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  children: List.generate(outlineIcons.length, (index) {
                    final isSelected = index == activeTab;

                    return GestureDetector(
                      onTap: () {
                        ref.read(homeTabProvider.notifier).state = index;
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 46,
                        height: 46,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: Icon(
                          isSelected ? filledIcons[index] : outlineIcons[index],
                          size: 22,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
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
