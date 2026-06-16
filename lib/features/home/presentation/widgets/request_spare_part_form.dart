import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class RequestSparePartForm extends StatefulWidget {
  const RequestSparePartForm({super.key});

  @override
  State<RequestSparePartForm> createState() => _RequestSparePartFormState();
}

class _RequestSparePartFormState extends State<RequestSparePartForm> {
  final _productController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _hasPhoto = false;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _productController.addListener(_validateForm);
    _vehicleController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _productController.dispose();
    _vehicleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isValid = _productController.text.trim().isNotEmpty &&
          _vehicleController.text.trim().isNotEmpty;
    });
  }

  void _onSubmit() {
    if (!_isValid) return;

    // Mostrar un diálogo/bottom sheet de éxito sumamente estético
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primaryMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Solicitud Enviada!',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hemos enviado tu requerimiento de repuesto a las tiendas afiliadas más cercanas. Te notificaremos en la sección de Chats apenas recibas cotizaciones.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra bottom sheet
                  // Limpia el formulario
                  _productController.clear();
                  _vehicleController.clear();
                  _detailsController.clear();
                  setState(() {
                    _hasPhoto = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
                child: Text(
                  'ENTENDIDO',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de la solicitud
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.settings_suggest_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solicita tu Repuesto',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Cotiza al instante con las tiendas cercanas',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),

          // Campo 1: Producto / Repuesto
          _buildLabel('REPUESTO QUE BUSCAS *'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _productController,
            hint: 'Ej. Kit de embrague, amortiguador delantero...',
            icon: Icons.search_outlined,
          ),
          const SizedBox(height: 18),

          // Campo 2: Vehículo
          _buildLabel('VEHÍCULO (AÑO, MARCA, MODELO) *'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _vehicleController,
            hint: 'Ej. 2015 Toyota Corolla 1.8L',
            icon: Icons.directions_car_filled_outlined,
          ),
          const SizedBox(height: 18),

          // Campo 3: Detalles adicionales (Opcional)
          _buildLabel('DETALLES ADICIONALES (OPCIONAL)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _detailsController,
            hint: 'Ej. Lado derecho, número de chasis (VIN)...',
            icon: Icons.description_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 18),

          // Campo 4: Fotografía
          _buildLabel('FOTOGRAFÍA DE REFERENCIA (OPCIONAL)'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _hasPhoto = !_hasPhoto;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              height: 90,
              decoration: BoxDecoration(
                color: _hasPhoto ? AppColors.primaryMuted : AppColors.grey50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _hasPhoto ? AppColors.primary : AppColors.border,
                  style: _hasPhoto ? BorderStyle.solid : BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _hasPhoto
                    ? [
                        const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'foto_repuesto_2026.jpg adjunta',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                      ]
                    : [
                        const Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Presiona para adjuntar foto',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Botón de Enviar Solicitud
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isValid ? _onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.grey200,
                disabledForegroundColor: AppColors.textDisabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                elevation: _isValid ? 6 : 0,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ENVIAR SOLICITUD',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.send_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 14 : 0, right: 12),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14.5,
                fontWeight: controller.text.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isCollapsed: true,
                hintText: hint,
                hintStyle: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textDisabled,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
