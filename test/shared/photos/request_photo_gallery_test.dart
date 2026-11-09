import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
import 'package:guiautomotriz_mobile/core/utils/media_url.dart';
import 'package:guiautomotriz_mobile/shared/photos/request_photo_gallery.dart';
import 'package:guiautomotriz_mobile/shared/photos/request_photos_controller.dart';
import 'package:guiautomotriz_mobile/shared/photos/request_photos_editor.dart';
import 'package:mocktail/mocktail.dart';

class _Client extends Mock implements HttpClient {}

class _Request extends Mock implements HttpClientRequest {}

class _Headers extends Mock implements HttpHeaders {}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.stream, this.contentLength, {this.statusCode = 200});
  final Stream<List<int>> stream;
  @override
  final int contentLength;
  @override
  final int statusCode;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> settlePhotos(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future.wait(tester.widgetList<Image>(find.byType(Image)).map((image) {
      final complete = Completer<void>();
      final stream = image.image.resolve(ImageConfiguration.empty);
      late ImageStreamListener listener;
      listener = ImageStreamListener((_, __) {
        if (!complete.isCompleted) complete.complete();
      }, onError: (_, __) {
        if (!complete.isCompleted) complete.complete();
      });
      stream.addListener(listener);
      return complete.future
          .whenComplete(() => stream.removeListener(listener));
    }));
  });
  await tester.pumpAndSettle();
}

void main() {
  late List<int> bytes;
  var status = 200;
  Stream<List<int>> Function()? responseStream;
  late HttpClient imageClient;

  void photoTest(String name, WidgetTesterCallback body) {
    testWidgets(name, (tester) async {
      debugNetworkImageHttpClientProvider = () => imageClient;
      try {
        await body(tester);
      } finally {
        debugNetworkImageHttpClientProvider = null;
      }
    });
  }

  setUpAll(() {
    registerFallbackValue(Uri());
    bytes = File('assets/images/categories/repuestos.png').readAsBytesSync();
  });
  setUp(() {
    status = 200;
    responseStream = null;
    final client = _Client();
    when(() => client.getUrl(any())).thenAnswer((_) async {
      final request = _Request();
      when(() => request.headers).thenReturn(_Headers());
      when(() => request.close()).thenAnswer((_) async => _Response(
          responseStream?.call() ?? Stream.value(bytes), bytes.length,
          statusCode: status));
      return request;
    });
    imageClient = client;
  });
  tearDown(() {
    debugNetworkImageHttpClientProvider = null;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  photoTest('explains an empty gallery', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RequestPhotoGallery(urls: []))));
    expect(
        find.text('Esta solicitud no tiene fotos adjuntas.'), findsOneWidget);
  });

  photoTest(
      'opens every photo with accessible next, previous and zoom controls',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: RequestPhotoGallery(urls: [
      'https://example.com/one.jpg',
      'https://example.com/two.jpg'
    ]))));
    await settlePhotos(tester);
    await tester.tap(find.bySemanticsLabel('Ver foto 2 de 2'));
    await settlePhotos(tester);
    expect(find.text('Foto 2 de 2'), findsOneWidget);
    expect(find.byTooltip('Acercar foto'), findsOneWidget);
    await tester.tap(find.byTooltip('Foto anterior'));
    await settlePhotos(tester);
    expect(find.text('Foto 1 de 2'), findsOneWidget);
    expect(tester.getSize(find.byTooltip('Cerrar fotos')).shortestSide,
        greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Cerrar fotos'));
    await settlePhotos(tester);
    semantics.dispose();
  });

  for (final width in [320.0, 430.0]) {
    photoTest('five photos stay in one swipeable row at $width and 2x text',
        (tester) async {
      tester.view.physicalSize = Size(width, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 44, bottom: 34)),
              child: child!),
          home: Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: RequestPhotoGallery(urls: [
                        for (var index = 0; index < 5; index++)
                          'http://localhost:3000/uploads/requests/$index.png'
                      ]))))));
      await settlePhotos(tester);
      final strip = find.byKey(const Key('request-photo-strip'));
      expect(tester.getSize(strip).height, 80);
      expect(find.byTooltip('Desliza para ver más fotos'), findsNothing);
      expect(tester.getSize(find.bySemanticsLabel('Ver foto 1 de 5')),
          const Size(80, 80));
      expect(
          find.image(NetworkImage(resolveMediaUrl(
              'http://localhost:3000/uploads/requests/0.png')!)),
          findsOneWidget);
      expect(find.byType(RawImage), findsWidgets);
      expect(
          tester
              .widgetList<RawImage>(find.byType(RawImage))
              .any((image) => image.image != null),
          isTrue);
      await tester.drag(strip, const Offset(-420, 0));
      await settlePhotos(tester);
      final last = find.bySemanticsLabel('Ver foto 5 de 5');
      expect(last.hitTestable(), findsOneWidget);
      await tester.tap(last);
      await settlePhotos(tester);
      expect(find.text('Foto 5 de 5'), findsOneWidget);
      expect(tester.getTopLeft(find.byTooltip('Cerrar fotos')).dy,
          greaterThanOrEqualTo(44));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  for (final width in [320.0, 430.0]) {
    photoTest('editor loads local photos and keeps stored URLs at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final urls = [
        for (var i = 0; i < 5; i++)
          'http://localhost:3000/uploads/requests/editor-$i.png'
      ];
      final controller =
          RequestPhotosController((_) async => 'unused', initialUrls: urls);
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 44, bottom: 34)),
              child: child!),
          home: Scaffold(
              body: SafeArea(
                  child: SingleChildScrollView(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child:
                              RequestPhotosEditor(controller: controller)))))));
      await settlePhotos(tester);
      expect(find.image(NetworkImage(resolveMediaUrl(urls.first)!)),
          findsOneWidget);
      expect(
          tester
              .widgetList<RawImage>(find.byType(RawImage))
              .any((image) => image.image != null),
          isTrue);
      expect(controller.urls, urls);
      await tester.tap(find.byTooltip('Eliminar foto 1'));
      await settlePhotos(tester);
      expect(controller.urls, urls.skip(1).toList());
      expect(find.text('Foto 1 · Portada'), findsOneWidget);
      expect(
          find.image(NetworkImage(resolveMediaUrl(urls[1])!)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  photoTest('shows loading until the image arrives', (tester) async {
    final pending = StreamController<List<int>>();
    responseStream = () => pending.stream;
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: RequestPhotoGallery(
                urls: ['https://example.com/loading.png']))));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.add(bytes);
    await pending.close();
    await settlePhotos(tester);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    expect(tester.takeException(), isNull);
  });

  photoTest('retries a failed photo from the viewer', (tester) async {
    status = 404;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: RequestPhotoGallery(
                urls: ['http://localhost:3000/uploads/missing.png']))));
    await settlePhotos(tester);
    await tester.tap(find.bySemanticsLabel('Ver foto 1 de 1'));
    await settlePhotos(tester);
    expect(find.text('No se pudo cargar la foto.'), findsOneWidget);
    status = 200;
    await tester.tap(find.text('Reintentar foto'));
    await settlePhotos(tester);
    expect(find.text('No se pudo cargar la foto.'), findsNothing);
    expect(
        tester
            .widgetList<RawImage>(find.byType(RawImage))
            .any((image) => image.image != null),
        isTrue);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
