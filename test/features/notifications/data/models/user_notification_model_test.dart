import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/notifications/data/models/user_notification_model.dart';

void main() {
  test('parses the REST notification contract with Mongo id and payload', () {
    final model = UserNotificationModel.fromJson(const {
      '_id': 'n-1',
      'tipo': 'offer.new',
      'titulo': 'Nueva oferta',
      'cuerpo': 'Mensaje completo',
      'data': {'offerId': 'o-1'},
      'leido': false,
      'createdAt': '2026-08-14T12:00:00.000Z',
    });

    expect(model.id, 'n-1');
    expect(model.type, 'offer.new');
    expect(model.title, 'Nueva oferta');
    expect(model.body, 'Mensaje completo');
    expect(model.data, const {'offerId': 'o-1'});
    expect(model.isRead, isFalse);
    expect(model.createdAt, DateTime.utc(2026, 8, 14, 12));
  });

  test('accepts realtime id and deterministic safe defaults', () {
    final model = UserNotificationModel.fromJson(const {
      'id': 'n-2',
      'tipo': 'unknown.kind',
      'titulo': 'Aviso',
      'cuerpo': 'Contenido',
      'createdAt': 'invalid',
    });

    expect(model.id, 'n-2');
    expect(model.type, 'unknown.kind');
    expect(model.data, isEmpty);
    expect(model.isRead, isFalse);
    expect(
      model.createdAt,
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  });

  test('normalizes loose maps and boolean read values safely', () {
    final model = UserNotificationModel.fromJson({
      '_id': 42,
      'tipo': 'message.new',
      'titulo': 'Mensaje',
      'cuerpo': 'Contenido',
      'data': <Object?, Object?>{'conversationId': 7},
      'leido': true,
      'createdAt': DateTime.utc(2026, 8, 14),
    });

    expect(model.id, '42');
    expect(model.data, const {'conversationId': 7});
    expect(model.isRead, isTrue);
    expect(model.createdAt, DateTime.utc(2026, 8, 14));
  });
}
