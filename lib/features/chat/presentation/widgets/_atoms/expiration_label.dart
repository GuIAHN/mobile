/// Formatea el tiempo restante hasta que expira una solicitud.
///
/// Antes existían dos copias de este cálculo con redondeo distinto
/// (`.ceil()` en una card, `.floor()` en otra), así que la misma solicitud
/// podía leer "Expira en 2d" o "Expira en 3d" según qué card la mostrara.
/// Se usa `.ceil()`: un countdown no debe mostrar "0d" cuando falta menos
/// de un día.
String expirationLabel(DateTime? expiresAt, {required bool isExpired}) {
  if (isExpired) return 'Expirada';
  if (expiresAt == null) return '';

  final diff = expiresAt.difference(DateTime.now());
  if (diff.isNegative) return 'Expirada';

  if (diff.inHours >= 24) {
    final days = (diff.inHours / 24).ceil();
    return 'Expira en ${days}d';
  }
  if (diff.inHours >= 1) return 'Expira en ${diff.inHours}h';
  if (diff.inMinutes > 0) return 'Expira en ${diff.inMinutes}m';
  return 'Expira pronto';
}
