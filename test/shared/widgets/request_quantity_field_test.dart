import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
import 'package:guiautomotriz_mobile/core/theme/app_theme.dart';
import 'package:guiautomotriz_mobile/shared/widgets/request_quantity_field.dart';

void main() {
  final input = find.byKey(const Key('request-quantity'));
  final decrease = find.byWidgetPredicate((widget) =>
      widget is IconButton && widget.tooltip == 'Disminuir cantidad');
  final increase = find.byWidgetPredicate((widget) =>
      widget is IconButton && widget.tooltip == 'Aumentar cantidad');

  Future<void> mount(WidgetTester tester, TextEditingController controller,
      {double scale = 1, GlobalKey<FormState>? formKey}) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
          padding: const EdgeInsets.only(top: 44, bottom: 34),
        ),
        child: child!,
      ),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: RequestQuantityField(controller: controller),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('steps within 1–999 and keeps the form value synchronized',
      (tester) async {
    final controller = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();
    addTearDown(controller.dispose);
    await mount(tester, controller, formKey: formKey);
    expect(tester.widget<IconButton>(decrease).onPressed, isNull);
    expect(find.text('unidad'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(increase);
    await tester.pump();
    expect(controller.text, '2');
    expect(find.text('unidades'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.tap(decrease);
    await tester.pump();
    expect(controller.text, '1');

    controller.text = '998';
    await tester.pump();
    await tester.tap(increase);
    await tester.pump();
    expect(controller.text, '999');
    expect(tester.widget<IconButton>(increase).onPressed, isNull);
    expect(formKey.currentState!.validate(), isTrue);
    await tester.tap(decrease);
    await tester.pump();
    expect(controller.text, '998');
  });

  testWidgets('direct entry filters digits and recovers empty and zero values',
      (tester) async {
    final controller = TextEditingController(text: '3');
    final formKey = GlobalKey<FormState>();
    addTearDown(controller.dispose);
    await mount(tester, controller, formKey: formKey);
    await tester.tap(input);
    await tester.pump();
    expect(controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 1));
    await tester.enterText(input, 'a1234');
    expect(controller.text, '123');

    for (final invalid in ['', '0']) {
      await tester.enterText(input, invalid);
      await tester.pump();
      expect(find.text('Ingresa una cantidad entre 1 y 999.'), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.tap(increase);
      await tester.pump();
      expect(controller.text, '1');
      expect(find.text('Ingresa una cantidad entre 1 y 999.'), findsNothing);
      expect(formKey.currentState!.validate(), isTrue);
    }
    await tester.enterText(input, '25');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(input).focusNode!.hasFocus, isFalse);
    expect(controller.text, '25');
  });

  for (final width in [320.0, 430.0]) {
    for (final scale in [1.0, 2.0, 3.2]) {
      testWidgets('three digits fit at width $width and text scale $scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 932);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = TextEditingController(text: '999');
        addTearDown(controller.dispose);
        await mount(tester, controller, scale: scale);
        expect(tester.takeException(), isNull);
        for (final button in [decrease, increase]) {
          expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        }
        final editable =
            tester.state<EditableTextState>(find.byType(EditableText));
        expect(
            (editable.renderEditable.offset as ScrollPosition).maxScrollExtent,
            0);
        expect(tester.getTopLeft(decrease).dy, greaterThanOrEqualTo(44));
        final semantics = tester.ensureSemantics();
        await tester.pump();
        expect(find.bySemanticsLabel('Cantidad de repuestos'), findsOneWidget);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      });
    }
  }
}
