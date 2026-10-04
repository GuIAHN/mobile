import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/offer_status.dart';

void main() {
  test('parses cancelled and keeps future status values tolerant', () {
    expect(OfferStatusX.fromApi('CANCELLED'), OfferStatus.cancelled);
    expect(OfferStatusX.fromApi('FUTURE_STATUS'), OfferStatus.unknown);
    expect(OfferStatus.cancelled.consumerLabel, 'CANCELADA');
  });
}
