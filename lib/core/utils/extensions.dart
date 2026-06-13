import 'package:flutter/material.dart';

/// Extensiones de utilidad para tipos comunes de Flutter.
/// Agrega métodos de conveniencia sin necesidad de wrappers.

// ── String extensions ─────────────────────────────────────────────────────────

extension StringExtensions on String {
  /// `"hello world"` → `"Hello world"`
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }

  /// `"hello world"` → `"Hello World"`
  String get titleCase {
    return split(' ')
        .map((word) => word.isEmpty ? word : word.capitalize)
        .join(' ');
  }

  /// Verifica si el string es un email válido.
  bool get isValidEmail {
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(this);
  }

  /// Convierte a iniciales: `"Juan Pérez"` → `"JP"`
  String get initials {
    final words = trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  /// Elimina acentos y caracteres especiales del español.
  String get withoutAccents {
    const accented = 'áéíóúüñÁÉÍÓÚÜÑ';
    const unaccented = 'aeiouunAEIOUUN';
    var result = this;
    for (var i = 0; i < accented.length; i++) {
      result = result.replaceAll(accented[i], unaccented[i]);
    }
    return result;
  }

  /// `null`-safe trim — equivalente a `?.trim() ?? ''`.
  String get safeTrim => trim();
}

extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  bool get isNotNullOrEmpty => !isNullOrEmpty;
  String get orEmpty => this ?? '';
}

// ── DateTime extensions ───────────────────────────────────────────────────────

extension DateTimeExtensions on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  bool get isPast => isBefore(DateTime.now());
  bool get isFuture => isAfter(DateTime.now());

  /// Inicio del día (00:00:00).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Fin del día (23:59:59).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
}

// ── BuildContext extensions ───────────────────────────────────────────────────

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;
  EdgeInsets get padding => mediaQuery.padding;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : null,
      ),
    );
  }
}

// ── num extensions ────────────────────────────────────────────────────────────

extension NumExtensions on num {
  /// `16.w(context)` — ancho proporcional a la pantalla.
  double w(BuildContext context) =>
      MediaQuery.of(context).size.width * this / 100;

  /// `16.h(context)` — alto proporcional a la pantalla.
  double h(BuildContext context) =>
      MediaQuery.of(context).size.height * this / 100;

  SizedBox get verticalSpace => SizedBox(height: toDouble());
  SizedBox get horizontalSpace => SizedBox(width: toDouble());
}

// ── List extensions ───────────────────────────────────────────────────────────

extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;

  /// Divide la lista en chunks de tamaño [size].
  List<List<T>> chunks(int size) {
    final result = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      result.add(sublist(i, (i + size).clamp(0, length)));
    }
    return result;
  }
}
