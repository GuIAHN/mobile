import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class RequestPhotoDraft {
  RequestPhotoDraft({this.file, this.url});
  final XFile? file;
  String? url;
  bool uploading = false;
  String? error;
}

/// Keeps successful uploads on retries and prevents publishing a partial set.
class RequestPhotosController extends ChangeNotifier {
  RequestPhotosController(this.upload,
      {Iterable<String> initialUrls = const []})
      : _photos =
            initialUrls.map((url) => RequestPhotoDraft(url: url)).toList();

  final Future<String> Function(String path) upload;
  final List<RequestPhotoDraft> _photos;
  bool _disposed = false;

  List<RequestPhotoDraft> get photos => List.unmodifiable(_photos);
  bool get canAdd => _photos.length < 5;
  bool get ready =>
      _photos.every((p) => !p.uploading && p.error == null && p.url != null);
  bool get uploading => _photos.any((p) => p.uploading);
  List<String> get urls {
    if (!ready) throw StateError('Hay fotografías pendientes de carga.');
    return _photos.map((p) => p.url!).toList(growable: false);
  }

  Future<void> add(XFile file) async {
    if (!canAdd || _disposed) return;
    final photo = RequestPhotoDraft(file: file);
    _photos.add(photo);
    await retry(photo);
  }

  Future<void> retry(RequestPhotoDraft photo) async {
    if (_disposed ||
        !_photos.contains(photo) ||
        photo.uploading ||
        photo.file == null) {
      return;
    }
    photo.uploading = true;
    photo.error = null;
    photo.url = null;
    _notify();
    try {
      final file = photo.file!;
      if (await file.length() > 5 * 1024 * 1024) {
        photo.error = 'La foto supera 5 MB. Elige una más pequeña.';
        return;
      }
      final bytes = await file.readAsBytes();
      final jpeg = bytes.length >= 3 &&
          bytes[0] == 0xff &&
          bytes[1] == 0xd8 &&
          bytes[2] == 0xff;
      const pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];
      final png =
          bytes.length >= 8 && listEquals(bytes.take(8).toList(), pngSignature);
      final webp = bytes.length >= 12 &&
          String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
          String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP';
      if (!jpeg && !png && !webp) {
        photo.error = 'Elige una foto JPEG, PNG o WebP.';
        return;
      }
      photo.url = await upload(file.path);
    } catch (_) {
      photo.error = 'No se pudo cargar la foto. Reintenta o elimínala.';
    } finally {
      photo.uploading = false;
      _notify();
    }
  }

  void remove(RequestPhotoDraft photo) {
    _photos.remove(photo);
    _notify();
  }

  /// New local uploads can expire before the request is finally published.
  void requireReupload() {
    for (final photo in _photos.where((p) => p.file != null)) {
      photo.url = null;
      photo.error = 'Vuelve a cargar la foto para continuar.';
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
