import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guiautomotriz_mobile/app.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GuiAutomotrizApp(),
      ),
    );
    expect(find.byType(GuiAutomotrizApp), findsOneWidget);
  });
}
