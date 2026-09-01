import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class StatusFilterOption<T> {
  const StatusFilterOption({
    required this.value,
    required this.label,
    required this.count,
  });

  final T value;
  final String label;
  final int count;
}

/// Selector de estado compartido por Solicitudes, Ventas y Compras.
///
/// Mantiene una única apariencia y comportamiento para el control compacto,
/// su contador y el bottom sheet de opciones.
class AppStatusFilterSelector<T> extends StatelessWidget {
  const AppStatusFilterSelector({
    super.key,
    required this.controlKey,
    required this.selected,
    required this.options,
    required this.onChanged,
    required this.optionKeyBuilder,
    this.singularNoun = 'solicitud',
    this.pluralNoun = 'solicitudes',
  });

  final Key controlKey;
  final T selected;
  final List<StatusFilterOption<T>> options;
  final ValueChanged<T> onChanged;
  final Key Function(T value) optionKeyBuilder;
  final String singularNoun;
  final String pluralNoun;

  @override
  Widget build(BuildContext context) {
    assert(options.isNotEmpty, 'El selector necesita al menos una opción.');
    final selectedOption = options.firstWhere(
      (option) => option.value == selected,
      orElse: () => options.first,
    );

    return Semantics(
      button: true,
      label:
          'Filtrar por estado. Seleccionado: ${selectedOption.label}, ${selectedOption.count}',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          key: controlKey,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => _showOptions(context),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.buttonHeightMd,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedOption.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatusCount(count: selectedOption.count, isSelected: true),
                const SizedBox(width: AppSpacing.sm),
                const AppLineIcon(
                  AppIcons.expand,
                  size: AppIconSize.inline,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showOptions(BuildContext context) async {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final choice = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      sheetAnimationStyle: AnimationStyle(
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
        reverseDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
      ),
      builder: (sheetContext) => Container(
        key: const Key('status-filter-sheet-surface'),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl2,
                AppSpacing.lg,
                AppSpacing.xl2,
                AppSpacing.sm,
              ),
              child: Text(
                'Filtrar por estado',
                textAlign: TextAlign.center,
                style: AppTypography.h2,
              ),
            ),
            Flexible(
              child: ListView(
                key: const Key('status-filter-list'),
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md + MediaQuery.paddingOf(sheetContext).bottom,
                ),
                children: [
                  for (final option in options)
                    _StatusFilterTile<T>(
                      option: option,
                      selected: option.value == selected,
                      optionKey: optionKeyBuilder(option.value),
                      singularNoun: singularNoun,
                      pluralNoun: pluralNoun,
                      onTap: () => Navigator.of(sheetContext).pop(option.value),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (choice != null && choice != selected) onChanged(choice);
  }
}

class _StatusFilterTile<T> extends StatelessWidget {
  const _StatusFilterTile({
    required this.option,
    required this.selected,
    required this.optionKey,
    required this.singularNoun,
    required this.pluralNoun,
    required this.onTap,
  });

  final StatusFilterOption<T> option;
  final bool selected;
  final Key optionKey;
  final String singularNoun;
  final String pluralNoun;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final noun = option.count == 1 ? singularNoun : pluralNoun;
    return Semantics(
      button: true,
      selected: selected,
      label: '${option.label}, ${option.count} $noun',
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          key: optionKey,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option.label,
                    style: AppTypography.body.copyWith(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                _StatusCount(count: option.count, isSelected: selected),
                const SizedBox(width: AppSpacing.md),
                SizedBox.square(
                  dimension: AppIconSize.action,
                  child: selected
                      ? const AppLineIcon(
                          AppIcons.selected,
                          size: AppIconSize.action,
                          color: AppColors.primary,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCount extends StatelessWidget {
  const _StatusCount({required this.count, required this.isSelected});

  final int count;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        '$count',
        style: AppTypography.meta.copyWith(
          fontWeight: FontWeight.w800,
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
