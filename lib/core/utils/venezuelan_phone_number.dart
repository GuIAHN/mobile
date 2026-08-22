/// Formato único para números móviles venezolanos usados por la app.
abstract final class VenezuelanPhoneNumber {
  static const List<String> mobilePrefixes = <String>[
    '0412',
    '0414',
    '0424',
    '0416',
    '0426',
    '0422',
  ];

  static final Set<String> _prefixes = mobilePrefixes.toSet();

  /// Convierte formatos locales, de API o con +58 a `04XX1234567`.
  ///
  /// Devuelve `null` cuando el número no pertenece a uno de los prefijos
  /// móviles admitidos o no contiene exactamente siete dígitos locales.
  static String? toLocal(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final trimmed = value.trim();
    if (!RegExp(r'^\+?[0-9\s\-()]+$').hasMatch(trimmed)) return null;

    var digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('58') && digits.length == 12) {
      digits = '0${digits.substring(2)}';
    } else if (digits.length == 10 && digits.startsWith('4')) {
      digits = '0$digits';
    }

    if (digits.length != 11 || !_prefixes.contains(digits.substring(0, 4))) {
      return null;
    }
    return digits;
  }

  /// Devuelve el formato nacional que ya consume el backend: `4XX1234567`.
  static String? toApi(String? value) {
    final local = toLocal(value);
    return local?.substring(1);
  }
}
