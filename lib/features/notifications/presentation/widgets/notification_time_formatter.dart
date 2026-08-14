abstract class NotificationTimeFormatter {
  NotificationTimeFormatter._();

  static String relative(DateTime date, {DateTime? now}) {
    final difference = (now ?? DateTime.now()).difference(date);
    if (difference.isNegative || difference.inSeconds < 60) return 'Ahora';
    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Hace $hours ${hours == 1 ? 'hora' : 'horas'}';
    }
    if (difference.inDays == 1) return 'Ayer';
    if (difference.inDays < 7) return 'Hace ${difference.inDays} días';
    return _date(date);
  }

  static String full(DateTime date) {
    return '${_date(date)} · ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  static String _date(DateTime date) {
    return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
