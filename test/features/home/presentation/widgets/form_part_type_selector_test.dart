import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/part_type.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/form_parts/form_part_type_selector.dart';

void main() {
  testWidgets('lets the requester select a used spare part', (tester) async {
    PartType? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormPartTypeSelector(
            selectedPartType: null,
            onPartTypeSelected: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.text('Usado'), findsOneWidget);
    expect(find.text('Repuesto previamente utilizado'), findsOneWidget);

    await tester.tap(find.text('Usado'));

    expect(selected?.apiValue, 'USED');
  });
}
