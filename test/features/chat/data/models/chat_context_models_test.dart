import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/chat/data/models/chat_conversation_model.dart';
import 'package:guiautomotriz_mobile/features/chat/data/models/chat_thread_model.dart';

void main() {
  test('thread model preserves nested catch-all and parent metadata', () {
    final model = ChatThreadModel.fromJson(const {
      'id': 'request-1',
      'title': 'Toyota Corolla',
      'requestType': 'spareParts',
      'createdAt': '2026-09-03T12:00:00.000Z',
      'subcategory': {
        'id': 'frenos-otro',
        'name': 'Nombre administrado',
        'isCatchAll': true,
        'parent': {'id': 'frenos', 'name': 'Frenos'},
      },
    });

    expect(model.subcategoryId, 'frenos-otro');
    expect(model.subcategory, 'Nombre administrado');
    expect(model.subcategoryIsCatchAll, isTrue);
    expect(model.categoryId, 'frenos');
    expect(model.categoryName, 'Frenos');
  });

  test('conversation model keeps legacy responses compatible', () {
    final model = ChatConversationModel.fromJson(const {
      'id': 'conversation-1',
      'subcategoryName': 'Pastillas',
    });

    expect(model.subcategoryName, 'Pastillas');
    expect(model.subcategoryIsCatchAll, isFalse);
    expect(model.categoryId, isNull);
    expect(model.categoryName, isNull);
  });
}
