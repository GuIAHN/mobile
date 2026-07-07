import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

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
      builder: (context) => QuoteInputDialog(requestTitle: title),
    );
  }

  @override
  State<QuoteInputDialog> createState() => _QuoteInputDialogState();
}

class _QuoteInputDialogState extends State<QuoteInputDialog> {
  bool _isFixedPrice = true;
  final _priceController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _priceController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _errorMessage = null;
    });

    if (_isFixedPrice) {
      final priceStr = _priceController.text.trim();
      if (priceStr.isEmpty) {
        setState(() => _errorMessage = 'Por favor ingresa el precio.');
        return;
      }
      final price = double.tryParse(priceStr);
      if (price == null || price <= 0) {
        setState(() => _errorMessage = 'Ingresa un precio válido mayor a 0.');
        return;
      }
      Navigator.pop(context, {
        'isFixedPrice': true,
        'price': price,
      });
    } else {
      final minStr = _minPriceController.text.trim();
      final maxStr = _maxPriceController.text.trim();

      if (minStr.isEmpty || maxStr.isEmpty) {
        setState(() => _errorMessage = 'Completa ambos precios del rango.');
        return;
      }

      final minPrice = double.tryParse(minStr);
      final maxPrice = double.tryParse(maxStr);

      if (minPrice == null || minPrice <= 0 || maxPrice == null || maxPrice <= 0) {
        setState(() => _errorMessage = 'Ingresa precios válidos mayores a 0.');
        return;
      }

      if (minPrice >= maxPrice) {
        setState(() => _errorMessage = 'El precio mínimo debe ser menor al máximo.');
        return;
      }

      Navigator.pop(context, {
        'isFixedPrice': false,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
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
        left: 24,
        right: 24,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 26,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          
          // Header
          Text(
            'Cotizar Repuesto',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.requestTitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // Price Type Selection (Fixed vs Range)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isFixedPrice = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isFixedPrice ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _isFixedPrice
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Precio Fijo',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13.5,
                          fontWeight: _isFixedPrice ? FontWeight.w800 : FontWeight.w600,
                          color: _isFixedPrice ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isFixedPrice = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isFixedPrice ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: !_isFixedPrice
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Rango Estimado',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13.5,
                          fontWeight: !_isFixedPrice ? FontWeight.w800 : FontWeight.w600,
                          color: !_isFixedPrice ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Dynamic Price Input Field(s)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isFixedPrice ? _buildFixedPriceInput() : _buildRangePriceInput(),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                color: AppColors.error,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          
          const SizedBox(height: 24),

          // CTA Button
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            child: Text(
              'ENVIAR COTIZACIÓN',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedPriceInput() {
    return Column(
      key: const ValueKey('fixed'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRECIO COTIZADO (\$)',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintText: 'Ej. 1200',
              hintStyle: GoogleFonts.hankenGrotesk(color: AppColors.textDisabled, fontWeight: FontWeight.w400),
              prefixIcon: const Icon(Icons.sell_outlined, color: AppColors.textSecondary, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRangePriceInput() {
    return Row(
      key: const ValueKey('range'),
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MÍNIMO (\$)',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    hintText: 'Ej. 800',
                    hintStyle: GoogleFonts.hankenGrotesk(color: AppColors.textDisabled, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MÁXIMO (\$)',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    hintText: 'Ej. 1000',
                    hintStyle: GoogleFonts.hankenGrotesk(color: AppColors.textDisabled, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
