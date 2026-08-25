import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/async_error_listener.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../../vehicles/domain/entities/brand.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';

/* ───────────────── Modelos ───────────────── */

class LineaCatalogo {
  final Category category;
  final Category parentCategory;
  Set<Brand> brands;
  Set<String> sparePartsTypes;

  LineaCatalogo({
    required this.category,
    required this.parentCategory,
    required this.brands,
    required this.sparePartsTypes,
  });
}

class ResultadoSheet {
  final bool eliminar;
  final bool servesAllBrands;
  final Set<Brand> brands;
  final Set<String> sparePartsTypes;

  const ResultadoSheet({
    this.eliminar = false,
    this.servesAllBrands = false,
    this.brands = const {},
    this.sparePartsTypes = const {},
  });
}

/* ───────────────── Funciones Auxiliares ───────────────── */

IconData getCategoryIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('motor')) return Icons.settings_outlined;
  if (lower.contains('transmisión') || lower.contains('caja')) {
    return Icons.account_tree_outlined;
  }
  if (lower.contains('suspensión') || lower.contains('dirección')) {
    return Icons.unfold_more_outlined;
  }
  if (lower.contains('freno')) return Icons.album_outlined;
  if (lower.contains('electricidad') || lower.contains('electrónico')) {
    return Icons.bolt_outlined;
  }
  if (lower.contains('latonería') ||
      lower.contains('pintura') ||
      lower.contains('carrocería')) {
    return Icons.format_paint_outlined;
  }
  return Icons.build_outlined;
}

/* ───────────────── Bottom Sheet de Selección de Marcas ───────────────── */

class SheetMarcas extends ConsumerStatefulWidget {
  final Category category;
  final Set<Brand> seleccionInicial;
  final Set<String> typesInicial;
  final bool existia;

  const SheetMarcas({
    super.key,
    required this.category,
    required this.seleccionInicial,
    required this.typesInicial,
    required this.existia,
  });

  @override
  ConsumerState<SheetMarcas> createState() => _SheetMarcasState();
}

class _SheetMarcasState extends ConsumerState<SheetMarcas> {
  late Set<Brand> _tempSeleccion;
  late Set<String> _tempTypes;
  String _filtro = '';
  final _filtroController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tempSeleccion = Set.from(widget.seleccionInicial);
    _tempTypes = Set.from(widget.typesInicial);
  }

  @override
  void dispose() {
    _filtroController.dispose();
    super.dispose();
  }

  bool _allBrandsSelected(List<Brand> allBrands) {
    if (allBrands.isEmpty) return false;
    final selectedIds = _tempSeleccion.map((brand) => brand.id).toSet();
    return allBrands.every((brand) => selectedIds.contains(brand.id));
  }

  void _toggleAllBrands(List<Brand> allBrands) {
    setState(() {
      if (_allBrandsSelected(allBrands)) {
        _tempSeleccion.clear();
      } else {
        _tempSeleccion.addAll(allBrands);
      }
    });
  }

  Widget _buildTypeChip(String value, String label) {
    final selected = _tempTypes.contains(value);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (selected) {
              if (_tempTypes.length > 1) {
                _tempTypes.remove(value);
              }
            } else {
              _tempTypes.add(value);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryMuted : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1.0,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listenAsyncError(brandsProvider, context);
    final brandsAsync = ref.watch(brandsProvider);
    final allBrands = brandsAsync.valueOrNull ?? [];
    final mediaQuery = MediaQuery.of(context);
    final usesLargeText = mediaQuery.textScaler.scale(14) >= 21;

    final filtradas = allBrands
        .where((m) => m.name.toLowerCase().contains(_filtro.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        height: mediaQuery.size.height * (usesLargeText ? 0.98 : 0.78),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            /* Handle y Cabecera */
            _AdaptiveSheetHeader(
              usesLargeText: usesLargeText,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: AppColors.textDisabled,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    Text(
                      widget.category.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selecciona las marcas que manejas para esta categoría',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    /* Campo Buscador */
                    TextField(
                      controller: _filtroController,
                      onChanged: (v) => setState(() => _filtro = v),
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar marca...',
                        hintStyle: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          color: AppColors.textDisabled,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: _filtro.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _filtro = '';
                                    _filtroController.clear();
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TIPOS DE REPUESTO',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTypeChip('ORIGINAL', 'Original'),
                        const SizedBox(width: 8),
                        _buildTypeChip('GENERIC', 'Genérico'),
                        const SizedBox(width: 8),
                        _buildTypeChip('PERFORMANCE', 'Performance'),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            /* Listado de Marcas */
            Expanded(
              child: brandsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (err, stack) => Center(
                  child: Text(
                    'Error al cargar marcas: $err',
                    style: GoogleFonts.hankenGrotesk(color: AppColors.error),
                  ),
                ),
                data: (_) {
                  if (allBrands.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay marcas disponibles en este momento.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  final allSelected = _allBrandsSelected(allBrands);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                        child: Semantics(
                          selected: allSelected,
                          child: SizedBox(
                            width: double.infinity,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: OutlinedButton.icon(
                                key: const Key('toggle-all-brands'),
                                onPressed: () => _toggleAllBrands(allBrands),
                                icon: Icon(
                                  allSelected
                                      ? Icons.deselect_rounded
                                      : Icons.select_all_rounded,
                                  size: 20,
                                ),
                                label: Text(
                                  allSelected
                                      ? 'Quitar todas las marcas'
                                      : 'Seleccionar todas (${allBrands.length})',
                                  textAlign: TextAlign.center,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  textStyle: GoogleFonts.hankenGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: filtradas.isEmpty
                            ? Center(
                                child: Text(
                                  'No se encontraron marcas con "$_filtro"',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 13.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: filtradas.length,
                                itemBuilder: (_, i) {
                                  final marca = filtradas[i];
                                  final seleccionado = _tempSeleccion
                                      .any((b) => b.id == marca.id);
                                  return GestureDetector(
                                    onTap: () => setState(() {
                                      if (seleccionado) {
                                        _tempSeleccion.removeWhere(
                                            (b) => b.id == marca.id);
                                      } else {
                                        _tempSeleccion.add(marca);
                                      }
                                    }),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: seleccionado
                                            ? AppColors.primaryMuted
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: seleccionado
                                              ? AppColors.primary
                                              : AppColors.border,
                                          width: seleccionado ? 1.6 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            seleccionado
                                                ? Icons.check_circle_rounded
                                                : Icons
                                                    .radio_button_off_rounded,
                                            size: 20,
                                            color: seleccionado
                                                ? AppColors.primary
                                                : AppColors.textDisabled,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              marca.name,
                                              style: GoogleFonts.hankenGrotesk(
                                                fontSize: 15,
                                                color: AppColors.textPrimary,
                                                fontWeight: seleccionado
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),

            /* Botones de Acción (Footer) */
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 26),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: (_tempSeleccion.isNotEmpty &&
                                _tempTypes.isNotEmpty)
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                )
                              ]
                            : [],
                      ),
                      child: ElevatedButton(
                        onPressed:
                            (_tempSeleccion.isNotEmpty && _tempTypes.isNotEmpty)
                                ? () => Navigator.pop(
                                      context,
                                      ResultadoSheet(
                                        servesAllBrands:
                                            _allBrandsSelected(allBrands),
                                        brands: _tempSeleccion,
                                        sparePartsTypes: _tempTypes,
                                      ),
                                    )
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: const Color(0xFFD9DCE1),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: const Color(0xFF9AA0A8),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _tempSeleccion.isEmpty
                              ? 'Guardar'
                              : 'Guardar (${_tempSeleccion.length} ${_tempSeleccion.length == 1 ? 'marca' : 'marcas'})',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.existia) ...[
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => Navigator.pop(
                        context,
                        const ResultadoSheet(eliminar: true),
                      ),
                      child: Text(
                        widget.category.id == 'general'
                            ? 'Limpiar configuración general'
                            : 'Quitar la categoría ${widget.category.name}',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdaptiveSheetHeader extends StatelessWidget {
  const _AdaptiveSheetHeader({
    required this.usesLargeText,
    required this.child,
  });

  final bool usesLargeText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!usesLargeText) return child;
    return Flexible(
      flex: 2,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: child,
      ),
    );
  }
}
