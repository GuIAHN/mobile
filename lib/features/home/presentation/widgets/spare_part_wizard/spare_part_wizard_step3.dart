part of 'spare_part_wizard_page.dart';

class SparePartWizardStep3 extends StatelessWidget {
  final UserCar? selectedVehicle;
  final Category? selectedCategory;
  final Category? selectedSubcategory;
  final PartType? selectedPartType;
  final TextEditingController detailsController;
  final TextEditingController? quantityController;
  final RequestPhotosController photosController;
  final RequestLocationSelection? requestLocation;
  final bool isLocatingLocation;
  final String? locationError;
  final VoidCallback onLocationTap;
  final VoidCallback? onEditVehicle;
  final VoidCallback? onEditPart;

  const SparePartWizardStep3({
    super.key,
    this.selectedVehicle,
    this.selectedCategory,
    this.selectedSubcategory,
    this.selectedPartType,
    required this.detailsController,
    this.quantityController,
    required this.photosController,
    required this.requestLocation,
    this.isLocatingLocation = false,
    this.locationError,
    required this.onLocationTap,
    this.onEditVehicle,
    this.onEditPart,
  });

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
          const _WizardStepIntro(
            icon: Icons.fact_check_outlined,
            eyebrow: 'CONFIRMACIÓN',
            title: 'Completa tu solicitud',
            description:
                'Revisa lo elegido y agrega la información para las tiendas.',
          ),
          if (selectedVehicle != null) ...[
            const SizedBox(height: 24),
            _WizardSelectionSummary(
              icon: Icons.directions_car_outlined,
              imageUrl: selectedVehicle!.computedBrandLogoUrl,
              eyebrow: 'VEHÍCULO',
              title: '${selectedVehicle!.brand} ${selectedVehicle!.model}',
              subtitle: 'Año ${selectedVehicle!.year}',
              actionLabel: 'Cambiar',
              onAction: onEditVehicle ?? () {},
            ),
          ],
          if (selectedSubcategory != null) ...[
            const SizedBox(height: 12),
            _WizardSelectionSummary(
              icon: Icons.settings_outlined,
              eyebrow: 'REPUESTO',
              title: _partTitle,
              subtitle: selectedPartType?.label,
              actionLabel: 'Editar',
              onAction: onEditPart ?? () {},
            ),
          ],
          const SizedBox(height: 32),
          if (quantityController != null) ...[
            RequestQuantityField(controller: quantityController!),
            const SizedBox(height: 24),
          ],
          const _WizardSectionHeader(
            icon: Icons.notes_rounded,
            title: 'Describe la pieza',
            helper: 'Indica características que ayuden a identificarla',
            badge: 'Requerido',
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('request-details'),
            controller: detailsController,
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
                '$currentLength/240',
                style: AppTypography.meta,
              );
            },
            decoration: InputDecoration(
              hintText: 'Ej. lado del conductor, con sensor, color gris',
              hintStyle: AppTypography.body.copyWith(
                color: AppColors.textPlaceholder,
              ),
              helperMaxLines: 6,
              helperStyle: AppTypography.bodySm,
              helperText:
                  'Incluye ubicación, medidas, versión o cualquier detalle útil.',
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
          const SizedBox(height: 32),
          const _WizardSectionHeader(
            icon: Icons.location_on_outlined,
            title: 'Indica la ubicación',
            helper: 'Dónde necesitas recibir respuestas',
            badge: 'Requerido',
          ),
          const SizedBox(height: 10),
          RequestLocationPreview(
            selection: requestLocation,
            isLocating: isLocatingLocation,
            errorMessage: locationError,
            onTap: onLocationTap,
          ),
          const SizedBox(height: 32),
          RequestPhotosEditor(controller: photosController),
        ],
      ),
    );
  }

  String get _partTitle {
    final subcategory = selectedSubcategory;
    return presentSubcategoryPath(
      categoryName: selectedCategory?.name,
      subcategoryName: subcategory?.name,
      isCatchAll: subcategory?.isCatchAll ?? false,
      audience: SubcategoryPresentationAudience.requester,
      sameCategoryAndSubcategory: selectedCategory?.id == subcategory?.id,
    );
  }
}
