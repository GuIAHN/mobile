part of 'spare_part_wizard_page.dart';

class _SparePartWizardStep3 extends ConsumerWidget {
  final TextEditingController detailsController;
  final String? selectedImagePath;
  final bool isOtroCategory;
  final void Function(String?) onImagePicked;
  final VoidCallback onSubmit;

  const _SparePartWizardStep3({
    super.key,
    required this.detailsController,
    required this.selectedImagePath,
    required this.isOtroCategory,
    required this.onImagePicked,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocationShared = ref.watch(isLocationSharedProvider);
    final userLocationAsync = ref.watch(userLocationProvider);
    final userLocation = userLocationAsync.valueOrNull;

    final needsDetails = isOtroCategory;
    final hasDetailsIfRequired = !needsDetails || detailsController.text.trim().isNotEmpty;
    // canSubmit requires location shared, location obtained, and details if required
    final canSubmit = hasDetailsIfRequired && isLocationShared && userLocation != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalles finales',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega cualquier detalle adicional que ayude a la tienda a encontrar la pieza correcta.',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          _buildLabel(needsDetails ? 'MÁS DETALLES (REQUERIDO) *' : 'MÁS DETALLES (OPCIONAL)'),
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
          _buildLocationMap(context, ref, isLocationShared, userLocation, userLocationAsync.isLoading),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: canSubmit ? 4 : 0,
              ),
              child: Text(
                'Enviar Solicitud',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMap(BuildContext context, WidgetRef ref, bool isLocationShared, Position? userLocation, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuiaMap(
          mapKey: ValueKey(userLocation),
          point: userLocation != null
              ? LatLng(userLocation.latitude, userLocation.longitude)
              : const LatLng(14.0723, -87.1921),
          isApproximate: !isLocationShared || userLocation == null,
        ),
        if (!isLocationShared || userLocation == null) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.center,
            child: isLoading
                ? const CircularProgressIndicator(color: AppColors.primary)
                : ElevatedButton.icon(
                    onPressed: () async {
                      final success = await ref.read(userLocationProvider.notifier).updateLocation();
                      if (success) {
                        ref.read(isLocationSharedProvider.notifier).state = true;
                      } else {
                        if (context.mounted) {
                          context.showSnackBar('No se pudo obtener la ubicación', isError: true);
                        }
                      }
                    },
                    icon: const Icon(Icons.share_location, size: 18),
                    label: Text(
                      'Compartir ubicación',
                      style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                      elevation: 0,
                    ),
                  ),
          ),
        ],
      ],
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
