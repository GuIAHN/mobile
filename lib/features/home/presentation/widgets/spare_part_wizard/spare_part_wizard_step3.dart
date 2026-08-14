part of 'spare_part_wizard_page.dart';

class SparePartWizardStep3 extends StatelessWidget {
  final TextEditingController detailsController;
  final String? selectedImagePath;
  final bool isOtroCategory;
  final RequestLocationSelection? requestLocation;
  final VoidCallback onLocationTap;
  final void Function(String?) onImagePicked;
  final VoidCallback onSubmit;

  const SparePartWizardStep3({
    super.key,
    required this.detailsController,
    required this.selectedImagePath,
    required this.isOtroCategory,
    required this.requestLocation,
    required this.onLocationTap,
    required this.onImagePicked,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final needsDetails = isOtroCategory;
    final hasDetailsIfRequired =
        !needsDetails || detailsController.text.trim().isNotEmpty;
    final hasLocation = requestLocation != null;
    final canSubmit = hasDetailsIfRequired && hasLocation;
    final blockedReason = !hasDetailsIfRequired
        ? 'Agrega un detalle para continuar.'
        : !hasLocation
            ? 'Elige una ubicación para continuar.'
            : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detalles finales', style: AppTypography.h1),
          const SizedBox(height: 8),
          Text(
            'Agrega cualquier detalle adicional que ayude a la tienda a encontrar la pieza correcta.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          _buildLabel(needsDetails
              ? 'MÁS DETALLES (REQUERIDO) *'
              : 'MÁS DETALLES (OPCIONAL)'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: detailsController,
            hint: 'Ej: Puerta del lado del conductor, color gris...',
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          _buildLabel('TU UBICACIÓN (REQUERIDA) *'),
          const SizedBox(height: 8),
          RequestLocationPreview(
            selection: requestLocation,
            onTap: onLocationTap,
          ),
          const SizedBox(height: 24),
          _buildLabel('AGREGAR UNA FOTO (OPCIONAL)'),
          const SizedBox(height: 8),
          _buildPhotoSelector(context),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: canSubmit ? onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.grey200,
                disabledForegroundColor: AppColors.textDisabled,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
                elevation: canSubmit ? 4 : 0,
              ),
              child: Text(
                'Enviar solicitud',
                style: AppTypography.label.copyWith(
                  fontSize: 16,
                  color: canSubmit ? Colors.white : AppColors.textDisabled,
                ),
              ),
            ),
          ),
          if (blockedReason != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Text(
                blockedReason,
                textAlign: TextAlign.center,
                style:
                    AppTypography.meta.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
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
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.hankenGrotesk(
          color: AppColors.textDisabled,
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final source = await ImageSourceSelectorSheet.show(context);
    if (source == null) return;

    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        onImagePicked(pickedFile.path);
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar(
          'Error al seleccionar imagen: $e',
          isError: true,
        );
      }
    }
  }

  Widget _buildPhotoSelector(BuildContext context) {
    if (selectedImagePath != null) {
      return Stack(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: kIsWeb
                  ? Image.network(
                      selectedImagePath!,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(selectedImagePath!),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => onImagePicked(null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pickImage(context),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                'Subir foto del repuesto',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
