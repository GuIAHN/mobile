part of 'spare_part_wizard_page.dart';

class _SparePartWizardStep2 extends ConsumerStatefulWidget {
  final UserCar? selectedVehicle;
  final Category? selectedCategory;
  final Category? selectedSubcategory;
  final PartType? selectedPartType;
  final void Function(Category?, Category?) onCategoryChanged;
  final void Function(PartType?) onPartTypeChanged;
  final VoidCallback onEditVehicle;

  const _SparePartWizardStep2({
    super.key,
    required this.selectedVehicle,
    required this.selectedCategory,
    required this.selectedSubcategory,
    required this.selectedPartType,
    required this.onCategoryChanged,
    required this.onPartTypeChanged,
    required this.onEditVehicle,
  });

  @override
  ConsumerState<_SparePartWizardStep2> createState() =>
      _SparePartWizardStep2State();
}

class _SparePartWizardStep2State extends ConsumerState<_SparePartWizardStep2> {
  String _categorySelectorValue() {
    if (widget.selectedCategory == null || widget.selectedSubcategory == null) {
      return '';
    }
    if (widget.selectedCategory!.id == widget.selectedSubcategory!.id) {
      return widget.selectedCategory!.name;
    }
    return '${widget.selectedCategory!.name} - ${widget.selectedSubcategory!.name}';
  }

  void _openCategorySelector() async {
    final result = await CategorySubcategorySelectorSheet.show(
      context,
      initialCategory: widget.selectedCategory,
      initialSubcategory: widget.selectedSubcategory,
    );
    if (result != null) {
      widget.onCategoryChanged(result.category, result.subcategory);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('spare-wizard-step-2'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WizardStepIntro(
            icon: Icons.settings_outlined,
            eyebrow: 'REPUESTO',
            title: '¿Qué pieza necesitas?',
            description: 'Selecciona la pieza y el tipo que prefieres recibir.',
          ),
          if (widget.selectedVehicle != null) ...[
            const SizedBox(height: 24),
            _WizardSelectionSummary(
              icon: Icons.directions_car_outlined,
              imageUrl: widget.selectedVehicle!.computedBrandLogoUrl,
              eyebrow: 'VEHÍCULO',
              title:
                  '${widget.selectedVehicle!.brand} ${widget.selectedVehicle!.model}',
              subtitle: 'Año ${widget.selectedVehicle!.year}',
              actionLabel: 'Cambiar',
              onAction: widget.onEditVehicle,
            ),
          ],
          const SizedBox(height: 32),
          const _WizardSectionHeader(
            icon: Icons.search_rounded,
            title: 'Busca la pieza',
            helper: 'Categoría y subcategoría',
            badge: 'Requerido',
          ),
          const SizedBox(height: 10),
          _SelectorField(
            value: _categorySelectorValue(),
            placeholder: 'Selecciona categoría y subcategoría',
            onTap: _openCategorySelector,
          ),
          const SizedBox(height: 32),
          const _WizardSectionHeader(
            icon: Icons.tune_rounded,
            title: 'Elige el tipo',
            helper: 'Origen o nivel de rendimiento',
            badge: 'Requerido',
          ),
          const SizedBox(height: 10),
          FormPartTypeSelector(
            selectedPartType: widget.selectedPartType,
            onPartTypeSelected: widget.onPartTypeChanged,
          ),
        ],
      ),
    );
  }
}

class _SelectorField extends StatelessWidget {
  final String value;
  final String placeholder;
  final VoidCallback onTap;

  const _SelectorField({
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasValue ? AppColors.primary : AppColors.border,
              width: hasValue ? 1.4 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textPrimary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasValue ? value : placeholder,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                    color: hasValue
                        ? AppColors.textPrimary
                        : AppColors.textDisabled,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
