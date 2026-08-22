import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/utils/validators.dart';
import 'package:guiautomotriz_mobile/core/utils/venezuelan_phone_number.dart';

void main() {
  group('VenezuelanPhoneNumber', () {
    test('defines every supported mobile prefix once', () {
      expect(
        VenezuelanPhoneNumber.mobilePrefixes,
        const ['0412', '0414', '0424', '0416', '0426', '0422'],
      );
      expect(
        VenezuelanPhoneNumber.mobilePrefixes.toSet().length,
        VenezuelanPhoneNumber.mobilePrefixes.length,
      );
    });

    test('normalizes local, API and country-code formats', () {
      expect(
        VenezuelanPhoneNumber.toLocal('0412 123 4567'),
        '04121234567',
      );
      expect(VenezuelanPhoneNumber.toLocal('4141234567'), '04141234567');
      expect(
        VenezuelanPhoneNumber.toLocal('+58 (424) 123-4567'),
        '04241234567',
      );
      expect(VenezuelanPhoneNumber.toApi('04261234567'), '4261234567');
    });

    test('rejects unknown prefixes and incomplete subscribers', () {
      expect(VenezuelanPhoneNumber.toLocal('04131234567'), isNull);
      expect(VenezuelanPhoneNumber.toLocal('0412123456'), isNull);
      expect(VenezuelanPhoneNumber.toLocal('0412ABC4567'), isNull);
      expect(Validators.phone('0412123456'), isNotNull);
      expect(Validators.phone('04121234567'), isNull);
    });
  });
}
