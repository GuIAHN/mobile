/// Converts user-facing text into a stable form for local search comparisons.
///
/// It keeps the original UI copy untouched. Only case and Latin diacritics
/// are folded; `ñ` remains distinct from `n` because it is a separate letter
/// in Spanish.
String normalizeSearchText(String value) {
  var normalized = value.trim().toLowerCase();

  // Preserve Spanish ñ when the input arrives in its decomposed Unicode form.
  normalized = normalized.replaceAll('n\u0303', 'ñ');

  const replacements = <String, String>{
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'ç': 'c',
  };

  for (final entry in replacements.entries) {
    normalized = normalized.replaceAll(entry.key, entry.value);
  }

  return normalized.replaceAll(RegExp(r'[\u0300-\u036f]'), '');
}
