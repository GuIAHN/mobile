import 'package:intl/intl.dart';

/// Formateadores de datos para la UI de guIAutomotriz.
/// Transforma tipos básicos a strings legibles para el usuario.
abstract class Formatters {
  Formatters._();

  // ── Fechas ────────────────────────────────────────────────────────────────

  static final _dateFormat = DateFormat('dd/MM/yyyy', 'es');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'es');
  static final _monthYearFormat = DateFormat('MMMM yyyy', 'es');
  static final _timeFormat = DateFormat('HH:mm', 'es');

  /// `2024-01-15` → `15/01/2024`
  static String date(DateTime date) => _dateFormat.format(date);

  /// `2024-01-15T10:30:00` → `15/01/2024 10:30`
  static String dateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);

  /// `2024-01-15` → `enero 2024`
  static String monthYear(DateTime date) => _monthYearFormat.format(date);

  /// `2024-01-15T10:30:00` → `10:30`
  static String time(DateTime dateTime) => _timeFormat.format(dateTime);

  /// Fecha relativa: "hace 2 días", "hace 3 horas", etc.
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Hace un momento';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return 'Hace $m ${m == 1 ? 'minuto' : 'minutos'}';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return 'Hace $h ${h == 1 ? 'hora' : 'horas'}';
    }
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    }
    return _dateFormat.format(date);
  }

  // ── Números ───────────────────────────────────────────────────────────────

  // Lempira hondureño. intl no trae datos para 'es_HN', por eso se usa
  // 'es_419' (español latinoamericano) con símbolo manual.
  static final _currencyFormat = NumberFormat.currency(
    locale: 'es_419',
    symbol: 'L ',
    decimalDigits: 2,
  );

  static final _currencyNoDecimals = NumberFormat.currency(
    locale: 'es_419',
    symbol: 'L ',
    decimalDigits: 0,
  );

  static final _compactFormat = NumberFormat.compact(locale: 'es');

  /// `1500000.50` → `L 1,500,000.50` (Lempira hondureño)
  static String currency(double amount) => _currencyFormat.format(amount);

  /// `1500` → `L 1,500` (sin decimales, para precios "desde")
  static String currencyCompact(double amount) =>
      _currencyNoDecimals.format(amount);

  /// `1500000` → `1,5M`
  static String compact(num number) => _compactFormat.format(number);

  /// `15000` → `15.000`
  static String thousands(num number) =>
      NumberFormat('#,###', 'es').format(number);

  // ── Kilometraje ────────────────────────────────────────────────────────────

  /// `55000` → `55.000 km`
  static String mileage(int km) => '${thousands(km)} km';

  // ── Texto ─────────────────────────────────────────────────────────────────

  /// Capitaliza la primera letra de cada palabra.
  static String titleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// Trunca texto largo con "...".
  static String truncate(String text, {int maxLength = 50}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // ── Placa ─────────────────────────────────────────────────────────────────

  /// Formatea la placa en mayúsculas.
  static String licensePlate(String plate) => plate.toUpperCase().trim();
}
