import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:guiautomotriz_mobile/shared/photos/request_photos_controller.dart';

XFile jpeg(String name) =>
    XFile.fromData(Uint8List.fromList([255, 216, 255, 0]),
        name: name, mimeType: 'image/jpeg');

void main() {
  test('blocks partial publishing and retries only the failed upload',
      () async {
    var calls = 0;
    final controller = RequestPhotosController((_) async {
      calls++;
      if (calls == 2) throw Exception('offline');
      return 'https://example.com/$calls.jpg';
    });
    addTearDown(controller.dispose);
    await controller.add(jpeg('one.jpg'));
    await controller.add(jpeg('two.jpg'));
    expect(controller.ready, isFalse);
    expect(() => controller.urls, throwsStateError);
    await controller.retry(controller.photos.last);
    expect(controller.urls,
        ['https://example.com/1.jpg', 'https://example.com/3.jpg']);
    expect(calls, 3);
    controller.remove(controller.photos.first);
    expect(controller.urls, ['https://example.com/3.jpg']);
  });

  test('limits slots to five and keeps the first as cover', () async {
    var calls = 0;
    final controller = RequestPhotosController(
        (_) async => 'https://example.com/${++calls}.jpg');
    addTearDown(controller.dispose);
    await Future.wait(List.generate(6, (i) => controller.add(jpeg('$i.jpg'))));
    expect(controller.photos, hasLength(5));
    expect(calls, 5);
    expect(controller.urls.first, 'https://example.com/1.jpg');
  });

  test('rejects invalid content and oversized files before uploading',
      () async {
    var calls = 0;
    final controller = RequestPhotosController((_) async {
      calls++;
      return 'url';
    });
    addTearDown(controller.dispose);
    await controller
        .add(XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'fake.jpg'));
    expect(controller.photos.last.error, contains('JPEG'));
    await controller
        .add(XFile.fromData(Uint8List(5 * 1024 * 1024 + 1), name: 'large.jpg'));
    expect(controller.photos.last.error, contains('5 MB'));
    expect(calls, 0);
  });

  test('removal during upload and disposal ignore a late completion', () async {
    final pending = Completer<String>();
    final controller = RequestPhotosController((_) => pending.future);
    final upload = controller.add(jpeg('one.jpg'));
    expect(controller.ready, isFalse);
    controller.remove(controller.photos.first);
    expect(controller.urls, isEmpty);
    controller.dispose();
    pending.complete('https://example.com/orphan.jpg');
    await upload;
  });

  test(
      'expiration keeps existing request photos but requires fresh local uploads',
      () async {
    final controller = RequestPhotosController(
        (_) async => 'https://example.com/new.jpg',
        initialUrls: ['https://example.com/existing.jpg']);
    addTearDown(controller.dispose);
    await controller.add(jpeg('new.jpg'));
    controller.requireReupload();
    expect(controller.ready, isFalse);
    expect(controller.photos.first.url, 'https://example.com/existing.jpg');
    expect(controller.photos.last.url, isNull);
    await controller.retry(controller.photos.last);
    expect(controller.ready, isTrue);
  });
}
