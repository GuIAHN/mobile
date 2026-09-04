enum SubcategoryPresentationAudience { requester, store }

const requesterCatchAllSubcategoryLabel = 'No sé cuál exactamente';
const storeCatchAllSubcategoryLabel = 'Sin categoría exacta — ver descripción';

String presentSubcategoryName({
  required String? name,
  required bool isCatchAll,
  required SubcategoryPresentationAudience audience,
  String fallback = 'Repuesto',
}) {
  if (isCatchAll) {
    return audience == SubcategoryPresentationAudience.store
        ? storeCatchAllSubcategoryLabel
        : requesterCatchAllSubcategoryLabel;
  }

  final normalizedName = name?.trim();
  return normalizedName == null || normalizedName.isEmpty
      ? fallback
      : normalizedName;
}

String presentSubcategoryPath({
  required String? categoryName,
  required String? subcategoryName,
  required bool isCatchAll,
  required SubcategoryPresentationAudience audience,
  bool sameCategoryAndSubcategory = false,
  String fallback = 'Repuesto',
}) {
  final presentedSubcategory = presentSubcategoryName(
    name: subcategoryName,
    isCatchAll: isCatchAll,
    audience: audience,
    fallback: fallback,
  );
  final normalizedCategory = categoryName?.trim();
  if (normalizedCategory == null || normalizedCategory.isEmpty) {
    return presentedSubcategory;
  }
  if (sameCategoryAndSubcategory) return normalizedCategory;
  return '$normalizedCategory › $presentedSubcategory';
}

String presentSparePartTitle({
  required String? spareBrand,
  required String? categoryName,
  required String? subcategoryName,
  required bool isCatchAll,
  required SubcategoryPresentationAudience audience,
  String fallback = 'Repuesto',
}) {
  final normalizedBrand = spareBrand?.trim();
  final hasBrand = normalizedBrand != null && normalizedBrand.isNotEmpty;
  final hasCategoryContext = isCatchAll ||
      categoryName?.trim().isNotEmpty == true ||
      subcategoryName?.trim().isNotEmpty == true;
  if (hasBrand && !hasCategoryContext) return normalizedBrand;

  final categoryPath = presentSubcategoryPath(
    categoryName: categoryName,
    subcategoryName: subcategoryName,
    isCatchAll: isCatchAll,
    audience: audience,
    fallback: fallback,
  );
  return hasBrand ? '$normalizedBrand · $categoryPath' : categoryPath;
}
