part of 'spare_part_wizard_page.dart';

class SparePartWizardStep3 extends StatefulWidget {
  final UserCar? selectedVehicle;
  final Category? selectedCategory;
  final Category? selectedSubcategory;
  final PartType? selectedPartType;
  final TextEditingController detailsController;
  final String? selectedImagePath;
  final bool isOtroCategory;
  final RequestLocationSelection? requestLocation;
  final VoidCallback onLocationTap;
  final VoidCallback? onEditVehicle;
  final VoidCallback? onEditPart;
  final VoidCallback? onSubmit;
  final void Function(String?) onImagePicked;

  const SparePartWizardStep3({
    super.key,
    this.selectedVehicle,
    this.selectedCategory,
    this.selectedSubcategory,
    this.selectedPartType,
    required this.detailsController,
    required this.selectedImagePath,
    required this.isOtroCategory,
    required this.requestLocation,
    required this.onLocationTap,
    this.onEditVehicle,
    this.onEditPart,
    this.onSubmit,
    required this.onImagePicked,
  });

  @override
  State<SparePartWizardStep3> createState() => _SparePartWizardStep3State();
}

class _SparePartWizardStep3State extends State<SparePartWizardStep3> {
  bool _isPickingImage = false;
  String? _imageError;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('spare-wizard-step-3'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Últimos detalles', style: AppTypography.h1),
          const SizedBox(height: 8),
          Text(
            'Ayuda a las tiendas a identificar la pieza y dónde la necesitas.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (widget.selectedVehicle != null) ...[
            const SizedBox(height: 20),
            _WizardSelectionSummary(
              icon: Icons.directions_car_outlined,
              eyebrow: 'VEHÍCULO',
              title: widget.selectedVehicle!.brand +
                  ' ' +
                  widget.selectedVehicle!.model,
              subtitle: 'Año ' + widget.selectedVehicle!.year.toString(),
              actionLabel: 'Cambiar',
              onAction: widget.onEditVehicle ?? () {},
            ),
          ],
          if (widget.selectedSubcategory != null) ...[
            const SizedBox(height: 8),
            _WizardSelectionSummary(
              icon: Icons.settings_outlined,
              eyebrow: 'REPUESTO',
              title: _partTitle,
              subtitle: widget.selectedPartType?.label,
              actionLabel: 'Editar',
              onAction: widget.onEditPart ?? () {},
            ),
          ],
          const SizedBox(height: 24),
          Text(
            widget.isOtroCategory
                ? 'DETALLES · REQUERIDOS'
                : 'DETALLES · OPCIONALES',
            style: AppTypography.overline,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.detailsController,
            minLines: 3,
            maxLines: 5,
            maxLength: 240,
            style: AppTypography.body,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) {
              return Text(
                currentLength.toString() + '/240',
                style: AppTypography.meta,
              );
            },
            decoration: InputDecoration(
              hintText: 'Ej. lado del conductor, con sensor, color gris',
              hintStyle: AppTypography.body.copyWith(
                color: AppColors.textPlaceholder,
              ),
              helperText: widget.isOtroCategory
                  ? 'Describe la pieza para que puedan identificarla.'
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('UBICACIÓN · REQUERIDA', style: AppTypography.overline),
          const SizedBox(height: 8),
          RequestLocationPreview(
            selection: widget.requestLocation,
            onTap: widget.onLocationTap,
          ),
          const SizedBox(height: 20),
          Text('FOTO · OPCIONAL', style: AppTypography.overline),
          const SizedBox(height: 8),
          _buildPhotoArea(context),
          if (_imageError != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                _imageError!,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.errorInk,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _partTitle {
    final category = widget.selectedCategory?.name;
    final subcategory = widget.selectedSubcategory?.name;
    if (category == null) return subcategory ?? 'Repuesto';
    if (subcategory == null || category == subcategory) return category;
    return category + ' › ' + subcategory;
  }

  Widget _buildPhotoArea(BuildContext context) {
    final path = widget.selectedImagePath;
    if (path != null) {
      final decodeWidth = (MediaQuery.sizeOf(context).width *
              MediaQuery.devicePixelRatioOf(context))
          .round();
      return Semantics(
        label: 'Foto del repuesto seleccionada',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final previewWidth = constraints.maxWidth.clamp(0.0, 320.0);
            return Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: previewWidth,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        kIsWeb
                            ? Image.network(
                                path,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const _PhotoErrorView(),
                              )
                            : Image.file(
                                File(path),
                                fit: BoxFit.cover,
                                cacheWidth: decodeWidth,
                                errorBuilder: (_, __, ___) =>
                                    const _PhotoErrorView(),
                              ),
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _PhotoOverlayAction(
                                icon: Icons.refresh_rounded,
                                label: 'Cambiar',
                                onTap: () => _showImageSourceSheet(context),
                              ),
                              const SizedBox(width: 8),
                              _PhotoOverlayAction(
                                icon: Icons.delete_outline_rounded,
                                label: 'Eliminar',
                                onTap: () => widget.onImagePicked(null),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 330;
        final camera = _PhotoSourceButton(
          icon: Icons.photo_camera_outlined,
          label: 'Tomar foto',
          loading: _isPickingImage,
          onPressed: () => _pickImage(context, ImageSource.camera),
        );
        final gallery = _PhotoSourceButton(
          icon: Icons.photo_library_outlined,
          label: 'Galería',
          loading: _isPickingImage,
          onPressed: () => _pickImage(context, ImageSource.gallery),
        );
        if (stack) {
          return Column(
            children: [camera, const SizedBox(height: 8), gallery],
          );
        }
        return Row(
          children: [
            Expanded(child: camera),
            const SizedBox(width: 12),
            Expanded(child: gallery),
          ],
        );
      },
    );
  }

  Future<void> _showImageSourceSheet(BuildContext context) async {
    final source = await ImageSourceSelectorSheet.show(context);
    if (source != null && context.mounted) {
      await _pickImage(context, source);
    }
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    if (_isPickingImage) return;
    setState(() {
      _isPickingImage = true;
      _imageError = null;
    });
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 86,
      );
      if (pickedFile != null) widget.onImagePicked(pickedFile.path);
    } catch (_) {
      if (mounted) {
        setState(() {
          _imageError = 'No pudimos abrir esa imagen. Intenta con otra foto.';
        });
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }
}

class _PhotoErrorView extends StatelessWidget {
  const _PhotoErrorView();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.grey100,
      child: Center(
        child: Text(
          'No pudimos mostrar esta foto. Elige otra imagen.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySm.copyWith(color: AppColors.errorInk),
        ),
      ),
    );
  }
}

class _PhotoSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _PhotoSourceButton({
    required this.icon,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryInk,
          side: const BorderSide(color: AppColors.border),
          shape: const StadiumBorder(),
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _PhotoOverlayAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoOverlayAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.label.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
