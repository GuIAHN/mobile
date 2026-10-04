enum NonDeliveryReason {
  outOfStock('SIN_STOCK', 'Sin stock'),
  incompatiblePart('PIEZA_NO_COMPATIBLE', 'Pieza no compatible'),
  incorrectPrice('PRECIO_INCORRECTO', 'Precio incorrecto'),
  deliveryUnavailable('NO_PUEDO_ENTREGAR', 'No puede entregar'),
  buyerUnresponsive('COMPRADOR_NO_RESPONDE', 'Comprador no responde'),
  other('OTRO', 'Otro');

  const NonDeliveryReason(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

String nonDeliveryReasonLabel(String value) {
  for (final reason in NonDeliveryReason.values) {
    if (reason.apiValue == value) return reason.label;
  }
  return value;
}
