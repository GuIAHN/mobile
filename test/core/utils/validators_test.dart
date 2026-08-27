import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/utils/validators.dart';

void main() {
  group('Validators.rif', () {
    test('acepta hasta 9 dígitos con o sin el prefijo J', () {
      expect(Validators.rif('123456789'), isNull);
      expect(Validators.rif('J123456789'), isNull);
    });

    test('rechaza un RIF con más de 9 dígitos', () {
      expect(
        Validators.rif('1234567890'),
        'El RIF debe tener un máximo de 9 dígitos.',
      );
    });

    test('rechaza caracteres que no sean numéricos', () {
      expect(
        Validators.rif('123A'),
        'El RIF solo puede contener números.',
      );
    });
  });
}
