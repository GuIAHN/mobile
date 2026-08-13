part of 'spare_part_wizard_page.dart';

class _SparePartWizardStep2 extends ConsumerStatefulWidget {
  final Category? selectedCategory;
  final Category? selectedSubcategory;
  final PartType? selectedPartType;
  final void Function(Category?, Category?) onCategoryChanged;
  final void Function(PartType?) onPartTypeChanged;
  final VoidCallback onNext;

  const _SparePartWizardStep2({
    super.key,
    required this.selectedCategory,
    required this.selectedSubcategory,
    required this.selectedPartType,
    required this.onCategoryChanged,
    required this.onPartTypeChanged,
    required this.onNext,
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
    // For now, if we don't have it exported, we would use a similar approach
    // Wait, since _CategorySubcategorySelectorSheet is private in the other file,
    // I need to either make it public or copy it.
    // Given we are replacing RequestSparePartForm eventually, we can create a public one.
    // Assuming we have CategorySubcategorySelectorSheet available in another file soon.
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
    final hasCategory =
        widget.selectedCategory != null && widget.selectedSubcategory != null;
    final hasPartType = widget.selectedPartType != null;
    final canProceed = hasCategory && hasPartType;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Qué repuesto necesitas?', style: AppTypography.h1),
          const SizedBox(height: 8),
          Text(
            'Indícanos la categoría y el tipo de repuesto.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          _buildLabel('CATEGORÍA DE REPUESTO *'),
          const SizedBox(height: 6),
          _SelectorField(
            value: _categorySelectorValue(),
            placeholder: 'Selecciona categoría y subcategoría',
            onTap: _openCategorySelector,
          ),
          const SizedBox(height: 24),
          _buildLabel('TIPO DE REPUESTO *'),
          const SizedBox(height: 8),
          FormPartTypeSelector(
            selectedPartType: widget.selectedPartType,
            onPartTypeSelected: widget.onPartTypeChanged,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: canProceed ? widget.onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.grey200,
                disabledForegroundColor: AppColors.textDisabled,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: canProceed ? 4 : 0,
              ),
              child: Text(
                'Continuar',
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
              // Ícono de "buscar en el catálogo" — este campo abre un
              // selector explorable, no despliega una lista en el lugar
              // (por eso no usa unfold_more, que sugiere lo segundo).
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hasValue ? AppColors.primaryMuted : AppColors.grey100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color:
                      hasValue ? AppColors.primaryInk : AppColors.textSecondary,
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
