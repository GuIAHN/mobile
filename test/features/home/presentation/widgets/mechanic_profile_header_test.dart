import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/provider_detail.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/mechanic_profile_header.dart';

const _photoUrl = 'https://example.com/mechanic-portrait.png';

Widget _subject({
  String? photo = _photoUrl,
  Size size = const Size(390, 844),
  double textScale = 1,
}) =>
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: const EdgeInsets.only(top: 44, bottom: 28),
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
          body: SafeArea(
              child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MechanicProfileHeader(
          detail: ProviderDetail(
            id: 'mechanic',
            nombre: 'Pedro Pérez (Mecánico)',
            esTaller: false,
            verified: true,
            photo: photo,
          ),
          heroTag: 'mechanic-photo',
        ),
      ))),
    );

void main() {
  setUp(() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(Colors.blue, BlendMode.src);
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 240, 40), Paint()..color = Colors.red);
    canvas.drawRect(
        const Rect.fromLTWH(0, 280, 240, 40), Paint()..color = Colors.green);
    final image = recorder.endRecording().toImageSync(240, 320);
    PaintingBinding.instance.imageCache.putIfAbsent(
      const NetworkImage(_photoUrl),
      () => OneFrameImageStreamCompleter(
          SynchronousFuture(ImageInfo(image: image))),
    );
  });

  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets('keeps the portrait next to the name and role', (tester) async {
    await tester.pumpWidget(_subject());
    await tester.pump();
    final photo = tester.getRect(find.byTooltip('Ver foto completa'));
    final name = tester.getRect(find.text('Pedro Pérez (Mecánico)'));
    expect(photo.right, lessThan(name.left));
    expect(photo.top, lessThanOrEqualTo(name.top));
    expect(find.text('Mecánico'), findsOneWidget);
    expect(tester.getSize(find.byType(MechanicProfileHeader)).height,
        lessThan(160));
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the entire original photo, zooms, resets and closes',
      (tester) async {
    await tester.pumpWidget(_subject());
    await tester.pump();
    await tester.tap(find.byTooltip('Ver foto completa'));
    await tester.pumpAndSettle();
    final viewer = find.byType(InteractiveViewer);
    expect(viewer, findsOneWidget);
    final rendered = tester.renderObject<RenderImage>(
      find.descendant(of: viewer, matching: find.byType(RawImage)),
    );
    expect(rendered.image, isNotNull);
    final original = Size(
        rendered.image!.width.toDouble(), rendered.image!.height.toDouble());
    expect(
        applyBoxFit(rendered.fit!, original, rendered.size).source, original);

    final controller =
        tester.widget<InteractiveViewer>(viewer).transformationController!;
    await tester.tap(find.byTooltip('Acercar foto'));
    await tester.pump();
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1));
    await tester.drag(viewer, const Offset(70, 40));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Alejar foto'));
    await tester.pump();
    expect(controller.value.getMaxScaleOnAxis(), 1);
    expect(controller.value.getTranslation().x, 0);
    expect(controller.value.getTranslation().y, 0);
    await tester.tap(find.byTooltip('Acercar foto'));
    await tester.pump();
    await tester.tap(find.text('Restablecer'));
    await tester.pump();
    expect(controller.value.getMaxScaleOnAxis(), 1);
    await tester.tap(find.byTooltip('Cerrar foto'));
    await tester.pumpAndSettle();
    expect(viewer, findsNothing);
    expect(find.text('Pedro Pérez (Mecánico)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adapts to small and large phones with enlarged text',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in [const Size(320, 720), const Size(480, 932)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_subject(size: size, textScale: 2));
      await tester.pump();
      expect(tester.getRect(find.text('Pedro Pérez (Mecánico)')).right,
          lessThanOrEqualTo(size.width - 16));
      await tester.tap(find.byTooltip('Ver foto completa'));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byTooltip('Cerrar foto')).top,
          greaterThanOrEqualTo(44));
      expect(tester.getSize(find.byTooltip('Cerrar foto')).shortestSide,
          greaterThanOrEqualTo(48));
      expect(tester.getRect(find.byTooltip('Acercar foto')).bottom,
          lessThanOrEqualTo(size.height - 28));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Cerrar foto'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('does not open an empty photo', (tester) async {
    await tester.pumpWidget(_subject(photo: null));
    await tester.pump();
    expect(find.byTooltip('Ver foto completa'), findsNothing);
    expect(find.text('Pedro Pérez (Mecánico)'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reset stays at the original size after a fast pinch release',
      (tester) async {
    await tester.pumpWidget(_subject());
    await tester.pump();
    await tester.tap(find.byTooltip('Ver foto completa'));
    await tester.pumpAndSettle();
    final viewer = find.byType(InteractiveViewer);
    final center = tester.getSize(viewer).center(Offset.zero);
    final gestures = tester.widget<GestureDetector>(
      find.descendant(of: viewer, matching: find.byType(GestureDetector)),
    );
    // Deliver a nonzero release velocity deterministically, without settling
    // the framework's inertia before pressing Reset.
    gestures.onScaleStart!(ScaleStartDetails(localFocalPoint: center));
    gestures
        .onScaleUpdate!(ScaleUpdateDetails(localFocalPoint: center, scale: 2));
    gestures.onScaleEnd!(ScaleEndDetails(scaleVelocity: 5));
    await tester.pump(const Duration(milliseconds: 16));
    final transform =
        tester.widget<InteractiveViewer>(viewer).transformationController!;
    expect(transform.value.getMaxScaleOnAxis(), greaterThan(1));
    await tester.tap(find.text('Restablecer'));
    await tester.pump(const Duration(milliseconds: 16));
    expect(transform.value.getMaxScaleOnAxis(), 1);
    await tester.pump(const Duration(milliseconds: 300));
    expect(transform.value.getMaxScaleOnAxis(), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows photo loading and a recoverable image error',
      (tester) async {
    PaintingBinding.instance.imageCache.clear();
    final pending = Completer<ImageInfo>();
    PaintingBinding.instance.imageCache.clearLiveImages();
    PaintingBinding.instance.imageCache.putIfAbsent(
      const NetworkImage(_photoUrl),
      () => OneFrameImageStreamCompleter(pending.future),
    );
    await tester.pumpWidget(_subject());
    await tester.pump();
    await tester.tap(find.byTooltip('Ver foto completa'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    pending.completeError(StateError('photo could not be decoded'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo cargar la foto'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.byTooltip('Cerrar foto'));
    await tester.pumpAndSettle();
    expect(find.text('Pedro Pérez (Mecánico)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
