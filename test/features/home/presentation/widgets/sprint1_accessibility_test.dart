import 'package:guiautomotriz_mobile/core/theme/app_typography.dart';
import 'package:guiautomotriz_mobile/core/theme/app_theme.dart';
import 'dart:convert';
import 'package:google_fonts/src/google_fonts_base.dart' as font_base;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/mechanic_level.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/_atoms/offer_price_breakdown.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/quote_input_dialog.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/provider_detail.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/mechanic_profile_header.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart';
import 'package:guiautomotriz_mobile/shared/photos/request_photos_controller.dart';

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  final dir = Platform.environment['SPRINT1_QA_DIR'];
  if (dir == null) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('$dir/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    final dir = Platform.environment['SPRINT1_QA_DIR'];
    if (dir == null) return;
    final bytes = ByteData.sublistView(
        await File('$dir/HankenGrotesk.ttf').readAsBytes());
    final fontManifest = jsonDecode(
        await File('build/unit_test_assets/FontManifest.json')
            .readAsString()) as List;
    for (final entry in fontManifest) {
      final loader = FontLoader(entry['family'] as String);
      for (final font in entry['fonts'] as List) {
        final asset = File('build/unit_test_assets/${font['asset']}');
        loader.addFont(
            Future.value(ByteData.sublistView(await asset.readAsBytes())));
      }
      await loader.load();
    }
    for (final variant in ['regular', '500', '600', '700', '800', '900']) {
      final loader = FontLoader('HankenGrotesk_$variant')
        ..addFont(Future.value(bytes));
      await loader.load();
    }
    font_base.assetManifest = _QaFontManifest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final path = utf8.decode(message!.buffer.asUint8List());
      if (path.startsWith('qa/HankenGrotesk-')) return bytes;
      final asset = File('build/unit_test_assets/$path');
      return await asset.exists()
          ? ByteData.sublistView(await asset.readAsBytes())
          : null;
    });
  });

  for (final width in [320.0, 430.0]) {
    testWidgets('request quantity and photos adapt at $width and 2x text',
        (tester) async {
      tester.view.physicalSize = Size(width, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final photos = RequestPhotosController((_) async => 'url');
      final quantity = TextEditingController(text: '3');
      final details = TextEditingController(text: 'Batería para uso diario');
      addTearDown(photos.dispose);
      addTearDown(quantity.dispose);
      addTearDown(details.dispose);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(2),
                      disableAnimations: true,
                      padding: const EdgeInsets.only(top: 44, bottom: 34)),
                  child: child!),
              home: Scaffold(
                  backgroundColor: AppColors.background,
                  body: SafeArea(
                      child: SparePartWizardStep3(
                          detailsController: details,
                          quantityController: quantity,
                          photosController: photos,
                          requestLocation: null,
                          onLocationTap: () {}))))));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('request-quantity')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, key, 'request-$width');
      await tester.ensureVisible(find.text('Agregar fotos'));
      await tester.pumpAndSettle();
      expect(
          tester
              .getSize(find.widgetWithText(FilledButton, 'Agregar fotos'))
              .height,
          greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
      await capture(tester, key, 'request-photos-$width');
      await tester.enterText(find.byKey(const Key('request-quantity')), '0');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      expect(find.text('Ingresa una cantidad entre 1 y 999.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'quote preview and professional level fit at $width and 2x text',
        (tester) async {
      tester.view.physicalSize = Size(width, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(2),
                      disableAnimations: true),
                  child: child!),
              home: Scaffold(
                  backgroundColor: AppColors.background,
                  body: SingleChildScrollView(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const MechanicProfileHeader(
                                    detail: ProviderDetail(
                                        id: 'm',
                                        nombre: 'Carlos Rodríguez',
                                        esTaller: false,
                                        level: MechanicLevel.engineer),
                                    heroTag: 'photo'),
                                const SizedBox(height: 24),
                                const OfferPriceBreakdown(
                                    productCost: 37.05,
                                    quantity: 3,
                                    unitPrice: 12.35,
                                    deliveryCost: 2,
                                    totalCost: 39.05,
                                    width: double.infinity),
                                Builder(
                                    builder: (context) => TextButton(
                                        onPressed: () => QuoteInputDialog.show(
                                            context, 'Batería', quantity: 3),
                                        child: Text('Cotizar',
                                            style: AppTypography.label))),
                              ])))))));
      await tester.pumpAndSettle();
      expect(find.text('Nivel profesional · Ingeniero'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, key, 'amounts-level-$width');
      await tester.ensureVisible(find.text('Cotizar'));
      await tester.tap(find.text('Cotizar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '12.35');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      expect(find.text('3 unidades · Subtotal \$37.05'), findsOneWidget);
      expect(
          tester
              .state<EditableTextState>(find.byType(EditableText).first)
              .renderEditable
              .offset
              .pixels,
          0);
      expect(tester.takeException(), isNull);
      await capture(tester, key, 'quote-$width');
    });
  }
}

class _QaFontManifest implements AssetManifest {
  @override
  List<String> listAssets() => [
        for (final variant in [
          'Thin',
          'ExtraLight',
          'Light',
          'Regular',
          'Medium',
          'SemiBold',
          'Bold',
          'ExtraBold',
          'Black'
        ])
          'qa/HankenGrotesk-$variant.ttf'
      ];
  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}
