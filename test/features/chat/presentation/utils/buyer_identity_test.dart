import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/shared/utils/buyer_identity.dart';

void main() {
  test('uses a stable initials-and-code alias across chat and notifications',
      () {
    expect(BuyerIdentity.alias('Taller El Motor'), 'TE-426F6F');
    expect(BuyerIdentity.alias('  taller  el motor '), 'TE-426F6F');
    expect(
        BuyerIdentity.aliasFromMessage('Taller El Motor: Hola'), 'TE-426F6F');
    expect(BuyerIdentity.alias('Taller El Norte'), isNot('TE-426F6F'));
    expect(BuyerIdentity.alias(null), matches(RegExp(r'^CL-[A-F0-9]{6}$')));
    expect(
        BuyerIdentity.aliasFromMessage('Sin autor'), BuyerIdentity.alias(null));
  });

  for (final status in [
    null,
    '',
    'INQUIRY',
    'SENT',
    'ACCEPTED',
    'DISCARDED',
    'UNKNOWN'
  ]) {
    test('a $status offer keeps the buyer identity hidden', () {
      expect(BuyerIdentity.displayName('Taller El Motor', status), 'TE-426F6F');
      expect(BuyerIdentity.avatarUrl('https://example.com/private.jpg', status),
          isNull);
    });
  }
  for (final status in ['BOUGHT', 'DELIVERED', 'CANCELLED']) {
    test('a confirmed $status purchase reveals the buyer', () {
      expect(BuyerIdentity.displayName('Taller El Motor', status),
          'Taller El Motor');
      expect(BuyerIdentity.avatarUrl('https://example.com/private.jpg', status),
          'https://example.com/private.jpg');
    });
  }
}
