import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Barra de búsqueda estándar con debounce y botón de filtros como acción
/// propia (no un ícono más escondido dentro del campo de texto).
///
/// El campo de texto y el botón de filtros son dos superficies tocables
/// claramente distintas — el patrón que usan Mercado Libre/Amazon — en vez
/// de apilar lupa + limpiar + filtro dentro de la misma píldora, donde el
/// filtro quedaba enterrado como un ícono más entre íconos.
class AppSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final int activeFilters;
  final VoidCallback? onFilterTap;
  final Duration debounce;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.activeFilters = 0,
    this.onFilterTap,
    this.debounce = const Duration(milliseconds: 300),
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  Timer? _debounceTimer;
  late bool _hasText = widget.controller.text.isNotEmpty;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleChanged(String value) {
    setState(() => _hasText = value.isNotEmpty);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () => widget.onChanged(value));
  }

  void _clear() {
    _debounceTimer?.cancel();
    widget.controller.clear();
    setState(() => _hasText = false);
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.only(left: 10, right: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
                boxShadow: AppDecorations.soft,
              ),
              child: Row(
                children: [
                  // Lupa en una insignia propia, no un ícono suelto:
                  // ancla visualmente el campo como "buscador", no como un
                  // input genérico con decoración.
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryMuted,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primaryInk,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      onChanged: _handleChanged,
                      textInputAction: TextInputAction.search,
                      style: AppTypography.body,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        isCollapsed: true,
                        hintText: widget.hintText,
                        hintStyle: AppTypography.body.copyWith(
                          color: AppColors.textDisabled,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_hasText)
                    Semantics(
                      button: true,
                      label: 'Limpiar búsqueda',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: _clear,
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox(
                          width: 40,
                          height: 44,
                          child: Center(
                            child: _ClearBadge(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (widget.onFilterTap != null) ...[
            const SizedBox(width: 10),
            _FilterButton(
              activeCount: widget.activeFilters,
              onTap: widget.onFilterTap!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Botón "x" para limpiar el texto: un cierre neutro sobre fondo gris,
/// no el glifo de "cancelar" (que semánticamente sugiere error/descartar).
class _ClearBadge extends StatelessWidget {
  const _ClearBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.grey100,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.close_rounded,
        size: 13,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// Botón de filtros: superficie propia junto al buscador (no un ícono
/// dentro de él), del mismo alto que la píldora de búsqueda para que ambas
/// lean como una sola barra de herramientas.
class _FilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const _FilterButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = activeCount > 0;

    return Semantics(
      button: true,
      label: isActive
          ? 'Filtros de búsqueda, $activeCount activos'
          : 'Filtros de búsqueda',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryMuted : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.border,
                  width: isActive ? 1.4 : 1,
                ),
                boxShadow: AppDecorations.soft,
              ),
              child: Icon(
                Icons.tune_rounded,
                color:
                    isActive ? AppColors.primaryInk : AppColors.textSecondary,
                size: 22,
              ),
            ),
            if (isActive)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  child: Text(
                    '$activeCount',
                    style: AppTypography.meta.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
