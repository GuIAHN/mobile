import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/* ───────────────── Modelos ───────────────── */

class CategoriaRepuesto {
  final String nombre;
  final IconData icono;
  final String desc;
  const CategoriaRepuesto(this.nombre, this.icono, this.desc);
}

class LineaCatalogo {
  final String categoria;
  Set<String> marcas;
  LineaCatalogo({
    required this.categoria,
    required this.marcas,
  });
}

class ResultadoSheet {
  final bool eliminar;
  final Set<String> marcas;
  const ResultadoSheet({this.eliminar = false, this.marcas = const {}});
}

/* ───────────────── Datos Estáticos del Catálogo ───────────────── */

const List<String> kMarcas = [
  'Toyota',
  'Chevrolet',
  'Ford',
  'Hyundai',
  'Kia',
  'Nissan',
  'Mitsubishi',
  'Volkswagen',
  'Jeep',
  'Mazda',
  'Honda',
  'Mercedes',
];

const List<CategoriaRepuesto> kCategorias = [
  CategoriaRepuesto(
    'Motor',
    Icons.settings_outlined,
    'Empacaduras, pistones, correas y bombas.',
  ),
  CategoriaRepuesto(
    'Transmisión',
    Icons.account_tree_outlined,
    'Croche, discos, collarines y soportes.',
  ),
  CategoriaRepuesto(
    'Suspensión',
    Icons.unfold_more_outlined,
    'Amortiguadores, mesetas y rótulas.',
  ),
  CategoriaRepuesto(
    'Frenos',
    Icons.album_outlined,
    'Pastillas, discos, tambores y bombas.',
  ),
  CategoriaRepuesto(
    'Electricidad',
    Icons.bolt_outlined,
    'Alternadores, bujías, sensores y baterías.',
  ),
  CategoriaRepuesto(
    'Latonería y Pintura',
    Icons.format_paint_outlined,
    'Faros, stops, parachoques y espejos.',
  ),
];

/* ───────────────── Bottom Sheet de Selección de Marcas ───────────────── */

class SheetMarcas extends StatefulWidget {
  final CategoriaRepuesto categoria;
  final Set<String> seleccionInicial;
  final bool existia;

  const SheetMarcas({
    super.key,
    required this.categoria,
    required this.seleccionInicial,
    required this.existia,
  });

  @override
  State<SheetMarcas> createState() => _SheetMarcasState();
}

class _SheetMarcasState extends State<SheetMarcas> {
  late Set<String> _tempSeleccion;
  String _filtro = '';
  final _filtroController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tempSeleccion = Set.from(widget.seleccionInicial);
  }

  @override
  void dispose() {
    _filtroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = kMarcas
        .where((m) => m.toLowerCase().contains(_filtro.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            /* Handle y Cabecera */
            Padding(
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
                    widget.categoria.nombre,
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
                  const SizedBox(height: 14),
                ],
              ),
            ),

            /* Listado de Marcas */
            Expanded(
              child: filtradas.isEmpty
                  ? Center(
                      child: Text(
                        'No se encontraron marcas con "$_filtro"',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filtradas.length,
                      itemBuilder: (_, i) {
                        final marca = filtradas[i];
                        final seleccionado = _tempSeleccion.contains(marca);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (seleccionado) {
                              _tempSeleccion.remove(marca);
                            } else {
                              _tempSeleccion.add(marca);
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
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
                                      : Icons.radio_button_off_rounded,
                                  size: 20,
                                  color: seleccionado
                                      ? AppColors.primary
                                      : AppColors.textDisabled,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    marca,
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
                        boxShadow: (_tempSeleccion.isNotEmpty || widget.existia)
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                )
                              ]
                            : [],
                      ),
                      child: ElevatedButton(
                        onPressed: (_tempSeleccion.isNotEmpty || widget.existia)
                            ? () => Navigator.pop(
                                  context,
                                  ResultadoSheet(marcas: _tempSeleccion),
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
                        'Quitar la categoría ${widget.categoria.nombre}',
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
