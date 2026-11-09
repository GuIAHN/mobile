import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/utils/quote_amounts.dart';
import 'package:guiautomotriz_mobile/shared/widgets/request_quantity_field.dart';

void main() {
  test('cent arithmetic does not lose precision or multiply delivery', () {
    expect(QuoteAmounts.cents('0,10'), 10);
    expect(QuoteAmounts.subtotal('0.10', 3), 0.30);
    expect(QuoteAmounts.total(0.30, 0.20), 0.50);
    expect(QuoteAmounts.subtotal('12.35', 999), 12337.65);
    expect(QuoteAmounts.cents('1.001'), isNull);
    expect(QuoteAmounts.cents('-1'), isNull);
    expect(QuoteAmounts.cents('NaN'), isNull);
  });

  test('quantity accepts only whole units between 1 and 999', () {
    for (final invalid in ['', '0', '-1', '1.5', '1000', 'abc']) {
      expect(RequestQuantityField.value(invalid), isNull, reason: invalid);
    }
    expect(RequestQuantityField.value('1'), 1);
    expect(RequestQuantityField.value('999'), 999);
  });
}
