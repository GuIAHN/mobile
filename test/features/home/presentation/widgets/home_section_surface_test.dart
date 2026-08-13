import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/home_section_surface.dart';

void main() {
  testWidgets('renders a full-width padded surface with border separators',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 200));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.background,
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
    final content = find.text('Contenido');
    final surfaceContainer = find.descendant(
      of: surface,
      matching: find.byType(Container),
    );
    final container = tester.widget<Container>(surfaceContainer);
    final border =
        (container.foregroundDecoration! as BoxDecoration).border! as Border;

    expect(tester.getSize(surface).width, 390);
    expect(container.color, AppColors.surface);
    expect(border.top.color, AppColors.border);
    expect(border.bottom.color, AppColors.border);
    expect(border.top.width, 1);
    expect(border.bottom.width, 1);
    expect(content, findsOneWidget);
    expect(
      tester.getTopLeft(content).dy - tester.getTopLeft(surface).dy,
      20,
    );
    expect(
      tester.getBottomLeft(surface).dy - tester.getBottomLeft(content).dy,
      20,
    );
  });
}
