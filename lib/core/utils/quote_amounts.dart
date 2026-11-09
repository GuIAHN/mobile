/// Preview arithmetic in integer cents. The server remains authoritative.
abstract final class QuoteAmounts {
  static const maxSubtotalCents = 9999999999;

  static int? cents(String text) {
    final normalized = text.trim().replaceAll(',', '.');
    if (!RegExp(r'^(?:\d+(?:\.\d{0,2})?|\.\d{1,2})$').hasMatch(normalized)) {
      return null;
    }
    final parts = normalized.split('.');
    final whole = int.tryParse(parts.first.isEmpty ? '0' : parts.first);
    if (whole == null) return null;
    final fraction = parts.length == 1 ? '00' : parts[1].padRight(2, '0');
    return whole * 100 + int.parse(fraction);
  }

  static double subtotal(String unitPrice, int quantity) =>
      ((cents(unitPrice) ?? 0) * quantity) / 100;

  static double? total(double? subtotal, double? delivery) => subtotal == null
      ? null
      : ((subtotal * 100).round() + ((delivery ?? 0) * 100).round()) / 100;
}
