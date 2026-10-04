import 'package:intl/intl.dart';

/// Formateadores de datos para la UI de guIAutomotriz.
abstract class Formatters {
  Formatters._();

  static final _dateFormat = DateFormat('dd/MM/yyyy', 'es');
  static final _currencyFormat = NumberFormat.currency(
    locale: 'es_419',
    symbol: r'$',
    decimalDigits: 2,
  );
  static final _currencyNoDecimals = NumberFormat.currency(
    locale: 'es_419',
    symbol: r'$',
    decimalDigits: 0,
  );

  /// Fecha relativa: "hace 2 días", "hace 3 horas", etc.
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Hace un momento';
    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return 'Hace $minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return 'Hace $hours ${hours == 1 ? 'hora' : 'horas'}';
    }
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return _dateFormat.format(date);
  }

  static String currency(double amount) => _currencyFormat.format(amount);

  static String currencyCompact(double amount) =>
      _currencyNoDecimals.format(amount);
}
