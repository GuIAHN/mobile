import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/home_section_surface.dart';

void main() {
  testWidgets('groups section content without adding a background or inset',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 200));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(height: 4),
              HomeSectionSurface(
                key: Key('home-section-surface'),
                child: Text('Contenido'),
              ),
              SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );

    const surfaceKey = Key('home-section-surface');
    final surface = find.byKey(surfaceKey);
    final contentSurface = find.byKey(const Key('home-section-content'));
    final content = find.text('Contenido');

    expect(tester.getSize(surface).width, 390);
    expect(tester.getSize(contentSurface).width, 390);
    expect(tester.getTopLeft(contentSurface).dx, 0);
    expect(tester.getBottomRight(contentSurface).dx, 390);
    expect(
      find.descendant(
        of: contentSurface,
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
    expect(content, findsOneWidget);
    expect(tester.getTopLeft(content).dy, tester.getTopLeft(contentSurface).dy);
    expect(
      tester.getBottomLeft(contentSurface).dy,
      tester.getBottomLeft(content).dy,
    );
  });
}
