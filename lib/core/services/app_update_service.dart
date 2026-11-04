import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  final service = AppUpdateService();
  ref.onDispose(service.dispose);
  return service;
});

/// Store checks are advisory and must never prevent the app from starting
/// when the store, network or platform plugins are unavailable.
class AppUpdateService extends Upgrader {
  AppUpdateService({super.storeController})
      : super(
          languageCode: 'es',
          durationUntilAlertAgain: const Duration(days: 1),
        );

  bool _disposed = false;

  /// Updates are always optional, including store minimum-version and
  /// critical-update metadata. These flags must not bypass reminder limits.
  @override
  bool blocked() => false;

  @override
  Future<bool> initialize() async {
    try {
      final initialized = await super.initialize();
      if (_disposed) super.dispose();
      return initialized;
    } catch (error) {
      debugPrint('[Updates] No se pudo consultar la tienda: $error');
      return false;
    }
  }

  @override
  Future<UpgraderVersionInfo?> updateVersionInfo() async {
    try {
      return await super
          .updateVersionInfo()
          .timeout(const Duration(seconds: 10));
    } catch (error) {
      debugPrint('[Updates] La tienda no está disponible: $error');
      return null;
    }
  }

  @override
  void updateState(UpgraderState newState,
      {bool updateTheVersionInfo = false}) {
    if (_disposed) return;
    super.updateState(newState, updateTheVersionInfo: updateTheVersionInfo);
  }

  Future<bool> openStore() async {
    final url = currentAppStoreListingURL;
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('[Updates] No se pudo abrir la tienda: $error');
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
    state.client.close();
  }
}
