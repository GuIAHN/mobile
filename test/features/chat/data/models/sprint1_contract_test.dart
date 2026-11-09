import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/mechanic_level.dart';
import 'package:guiautomotriz_mobile/core/utils/request_photo_urls.dart';
import 'package:guiautomotriz_mobile/features/chat/data/models/chat_conversation_model.dart';
import 'package:guiautomotriz_mobile/features/home/data/models/provider_detail_model.dart';
import 'package:guiautomotriz_mobile/features/purchases/data/models/consumer_purchase_model.dart';

void main() {
  test('reads ordered photos and old cover-only responses', () {
    expect(
        requestPhotoUrls({
          'photoUrl': 'cover',
          'photos': [
            {'url': 'two', 'position': 1},
            {'url': 'one', 'position': 0}
          ]
        }),
        ['one', 'two']);
    expect(requestPhotoUrls({'photoUrl': 'cover'}), ['cover']);
    expect(requestPhotoUrls({}), isEmpty);
  });

  test('realtime copies retain unit amounts and preserve fractional cents', () {
    final conversation = ChatConversationModel.fromJson(const {
      'id': 'chat',
      'quantity': 3,
      'unitPrice': 0.15,
      'price': 0.45,
      'deliveryCost': 0.20,
      'hasQuote': true
    });
    final update = conversation.withRealtimePreview(
        lastMessage: 'Hola',
        lastMessageIsFromMe: true,
        unreadCount: 0,
        lastMessageAt: DateTime.now());
    expect(update.quantity, 3);
    expect(update.unitPrice, 0.15);
    expect(update.formattedTotalCost, r'$0.65');
    expect(ChatConversationModel.fromJson(const {'id': 'old'}).quantity, 1);
  });

  test('purchase uses server subtotal and total without multiplying again', () {
    final purchase = ConsumerPurchaseModel.fromJson(const {
      'searchRequestId': 'r',
      'quantity': 3,
      'unitPrice': 12.35,
      'price': 37.05,
      'deliveryCost': 2,
      'totalCost': 39.05
    });
    expect(purchase.quantity, 3);
    expect(purchase.price, 37.05);
    expect(purchase.resolvedTotal, 39.05);
  });

  test(
      'professional level is independent of reviews and tolerates unknown values',
      () {
    final mechanic = ProviderDetailModel.fromMechanicJson(
        const {'id': 'm', 'level': 3, 'rating': 2.5, 'ratingCount': 4});
    expect(mechanic.level, MechanicLevel.engineer);
    expect(mechanic.rating, 2.5);
    expect(MechanicLevel.fromApi(4), isNull);
    expect(MechanicLevel.fromApi('2')?.label, 'TSU');
  });
}
