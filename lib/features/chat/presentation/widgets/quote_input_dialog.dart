import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/widgets/image_source_selector_sheet.dart';
import 'dart:io';

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
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();
  String? _selectedImagePath;
  final ImagePicker _picker = ImagePicker();
  String? _errorMessage;

  @override
  void dispose() {
    _priceController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _errorMessage = null;
    });

    final brandStr = _brandController.text.trim();
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
      if (brandStr.isNotEmpty) 'brand': brandStr,
      if (_selectedImagePath != null) 'photoPath': _selectedImagePath,
    });
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

          _buildFixedPriceInput(),

          const SizedBox(height: 20),

          // Brand Input Field
          Text(
            'MARCA DEL REPUESTO (OPCIONAL)',
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
              controller: _brandController,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                hintText: 'Ej. Bosch, Toyota, etc.',
                hintStyle: GoogleFonts.hankenGrotesk(color: AppColors.textDisabled, fontWeight: FontWeight.w400),
                prefixIcon: const Icon(Icons.branding_watermark_outlined, color: AppColors.textSecondary, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Image Picker
          Text(
            'FOTO DEL REPUESTO (OPCIONAL)',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _mostrarSelectorDeImagen,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: _selectedImagePath != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            File(_selectedImagePath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                        const Center(
                          child: Icon(Icons.edit_outlined, color: Colors.white, size: 28),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 28),
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



  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
        });
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
    if (source != null) {
      _pickImage(source);
    }
  }
}
