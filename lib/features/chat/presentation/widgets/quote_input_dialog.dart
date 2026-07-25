import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/image_source_selector_sheet.dart';

/// Modalidad de la oferta.
enum _QuoteMode { fixed, range }

/// Formatea el texto con separadores de miles mientras se escribe
/// (`12500` → `12,500`), limitando a 8 dígitos.
/// Permite ingresar montos numéricos con decimales (máximo 8 enteros, 2 decimales),
/// permitiendo el uso de punto o coma como separador decimal.
class _DecimalFormatter extends TextInputFormatter {
  final int maxIntegerDigits;
  final int maxDecimalDigits;

  _DecimalFormatter({this.maxIntegerDigits = 8, this.maxDecimalDigits = 2});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Normaliza coma a punto
    String text = newValue.text.replaceAll(',', '.');

    // Valida que solo tenga dígitos y como máximo un punto decimal
    final regExp = RegExp(r'^[0-9]*\.?[0-9]*$');
    if (!regExp.hasMatch(text)) {
      return oldValue;
    }

    // Separa la parte entera y decimal
    final parts = text.split('.');
    if (parts[0].length > maxIntegerDigits) {
      return oldValue;
    }

    if (parts.length > 1 && parts[1].length > maxDecimalDigits) {
      return oldValue;
    }

    int selectionIndex = newValue.selection.end;
    if (selectionIndex > text.length) {
      selectionIndex = text.length;
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

/// Hoja de cotización con entrada de monto limpia: número grande en naranja
/// con símbolo `$`, sin fondo ni teclado propio (usa el teclado del sistema).
/// Permite ofertar un precio fijo o un rango estimado.
///
/// Mantiene la misma API pública para no alterar al consumidor:
/// devuelve `{isFixedPrice, price?, minPrice?, maxPrice?, brand?, photoPath?}`.
class QuoteInputDialog extends StatefulWidget {
  final String requestTitle;

  const QuoteInputDialog({
    super.key,
    required this.requestTitle,
  });

  static Future<Map<String, dynamic>?> show(BuildContext context, String title) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => QuoteInputDialog(requestTitle: title),
    );
  }

  @override
  State<QuoteInputDialog> createState() => _QuoteInputDialogState();
}

class _QuoteInputDialogState extends State<QuoteInputDialog> {
  _QuoteMode _mode = _QuoteMode.fixed;

  final _fixedController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final _brandController = TextEditingController();

  final _fixedFocus = FocusNode();
  final _minFocus = FocusNode();

  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Actualiza el estado del botón al escribir.
    for (final c in [_fixedController, _minController, _maxController]) {
      c.addListener(() => setState(() => _errorMessage = null));
    }
  }

  @override
  void dispose() {
    _fixedController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _brandController.dispose();
    _fixedFocus.dispose();
    _minFocus.dispose();
    super.dispose();
  }

  double? _value(TextEditingController c) {
    final text = c.text.replaceAll(',', '.').trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  bool get _canSubmit {
    if (_mode == _QuoteMode.fixed) {
      final p = _value(_fixedController);
      return p != null && p > 0;
    }
    final min = _value(_minController);
    final max = _value(_maxController);
    return min != null && max != null && min > 0 && max > 0 && min < max;
  }

  void _submit() {
    setState(() => _errorMessage = null);
    final brand = _brandController.text.trim();

    if (_mode == _QuoteMode.fixed) {
      final price = _value(_fixedController);
      if (price == null || price <= 0) {
        setState(() => _errorMessage = 'Ingresa un precio mayor a 0.');
        return;
      }
      HapticFeedback.mediumImpact();
      Navigator.pop(context, {
        'isFixedPrice': true,
        'price': price,
        if (brand.isNotEmpty) 'brand': brand,
        if (_selectedImagePath != null) 'photoPath': _selectedImagePath,
      });
    } else {
      final min = _value(_minController);
      final max = _value(_maxController);
      if (min == null || min <= 0 || max == null || max <= 0) {
        setState(() => _errorMessage = 'Completa el rango con montos válidos.');
        return;
      }
      if (min >= max) {
        setState(() =>
            _errorMessage = 'El monto máximo debe ser mayor al mínimo.');
        return;
      }
      HapticFeedback.mediumImpact();
      Navigator.pop(context, {
        'isFixedPrice': false,
        'minPrice': min,
        'maxPrice': max,
        if (brand.isNotEmpty) 'brand': brand,
        if (_selectedImagePath != null) 'photoPath': _selectedImagePath,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),

              // Encabezado
              Text(
                'Enviar oferta',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.requestTitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),

              // Toggle Fijo / Rango
              _ModeToggle(
                mode: _mode,
                onChanged: (m) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _mode = m;
                    _errorMessage = null;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (m == _QuoteMode.fixed) {
                      _fixedFocus.requestFocus();
                    } else {
                      _minFocus.requestFocus();
                    }
                  });
                },
              ),
              const SizedBox(height: 26),

              // Monto: número grande naranja con $
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _mode == _QuoteMode.fixed
                    ? Padding(
                        key: const ValueKey('fixed'),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _AmountField(
                          controller: _fixedController,
                          focusNode: _fixedFocus,
                          autofocus: true,
                          fontSize: 72,
                        ),
                      )
                    : Padding(
                        key: const ValueKey('range'),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _LabeledAmount(
                                label: 'DESDE',
                                controller: _minController,
                                focusNode: _minFocus,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 56,
                              margin: const EdgeInsets.only(top: 24),
                              color: AppColors.border,
                            ),
                            Expanded(
                              child: _LabeledAmount(
                                label: 'HASTA',
                                controller: _maxController,
                                focusNode: null,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 15, color: AppColors.error),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.hankenGrotesk(
                          color: AppColors.error,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              const _ThinDivider(),
              const SizedBox(height: 20),

              // Detalles opcionales
              _OptionalDetails(
                brandController: _brandController,
                imagePath: _selectedImagePath,
                onPickImage: _mostrarSelectorDeImagen,
              ),
              const SizedBox(height: 24),

              // CTA
              _SubmitButton(enabled: _canSubmit, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _selectedImagePath = pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  void _mostrarSelectorDeImagen() async {
    final source = await ImageSourceSelectorSheet.show(context);
    if (source != null) _pickImage(source);
  }
}

// ── Campo de monto: $ + número grande naranja, sin fondo ────────────────────

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final double fontSize;

  const _AmountField({
    required this.controller,
    required this.focusNode,
    this.autofocus = false,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            r'$',
            style: GoogleFonts.hankenGrotesk(
              fontSize: fontSize * 0.40,
              fontWeight: FontWeight.w700,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutQuart,
              alignment: Alignment.centerLeft,
              child: IntrinsicWidth(
                child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: autofocus,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.left,
                cursorColor: AppColors.primary,
                inputFormatters: [_DecimalFormatter()],
                style: GoogleFonts.hankenGrotesk(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  height: 1.0,
                  color: AppColors.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintText: '00.00',
                  hintStyle: GoogleFonts.hankenGrotesk(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    height: 1.0,
                    color: AppColors.primary.withValues(alpha: 0.28),
                  ),
                ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Monto con etiqueta arriba (para el modo rango).
class _LabeledAmount extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;

  const _LabeledAmount({
    required this.label,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _AmountField(
          controller: controller,
          focusNode: focusNode,
          fontSize: 48,
        ),
      ],
    );
  }
}

// ── Toggle de modalidad ──────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final _QuoteMode mode;
  final ValueChanged<_QuoteMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segment('Precio fijo', _QuoteMode.fixed),
          _segment('Rango estimado', _QuoteMode.range),
        ],
      ),
    );
  }

  Widget _segment(String label, _QuoteMode value) {
    final selected = mode == value;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Detalles opcionales (marca + foto) ──────────────────────────────────────

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.border);
  }
}

class _OptionalDetails extends StatelessWidget {
  final TextEditingController brandController;
  final String? imagePath;
  final VoidCallback onPickImage;

  const _OptionalDetails({
    required this.brandController,
    required this.imagePath,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('MARCA DEL REPUESTO (OPCIONAL)'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: brandController,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.hankenGrotesk(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintText: 'Ej. Bosch, Toyota, etc.',
              hintStyle: GoogleFonts.hankenGrotesk(
                color: AppColors.textDisabled,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.branding_watermark_outlined,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _label('FOTO DEL REPUESTO (OPCIONAL)'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPickImage,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: imagePath != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(File(imagePath!), fit: BoxFit.cover),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                      const Center(
                        child: Icon(Icons.edit_outlined,
                            color: Colors.white, size: 28),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.primary, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'Agregar Foto',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1.0,
      ),
    );
  }
}

// ── Botón de envío ───────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _SubmitButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFD9DCE1),
          disabledForegroundColor: const Color(0xFF9AA0A8),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ENVIAR OFERTA',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.send_rounded, size: 17),
          ],
        ),
      ),
    );
  }
}
