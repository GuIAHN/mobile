import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guiautomotriz_mobile/app.dart';
import 'package:guiautomotriz_mobile/core/services/app_update_service.dart';

class _NoStoreUpdateService extends AppUpdateService {
  @override
  Future<bool> initialize() async => false;
}

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    final updates = _NoStoreUpdateService();
    addTearDown(updates.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appUpdateServiceProvider.overrideWithValue(updates)],
        child: const GuiAutomotrizApp(),
      ),
    );
    expect(find.byType(GuiAutomotrizApp), findsOneWidget);
  });
}
