import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/services/app_update_service.dart';
import 'package:upgrader/upgrader.dart';

class _Store extends UpgraderStore {
  String latest = '1.0.10';
  String? minimum;
  bool critical = false;
  bool fail = false;

  @override
  Future<UpgraderVersionInfo> getVersionInfo({
    required UpgraderState state,
    required dynamic installedVersion,
    required String? country,
    required String? language,
  }) async {
    if (fail) throw StateError('Store unavailable');
    return UpgraderVersionInfo(
      installedVersion: installedVersion,
      appStoreVersion: Upgrader.parseVersion(latest, 'latest', false),
      minAppVersion: Upgrader.parseVersion(minimum, 'minimum', false),
      isCriticalUpdate: critical,
      appStoreListingURL: 'https://apps.apple.com/app/id123',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const prefs = MethodChannel('plugins.flutter.io/shared_preferences');
  const packageInfo = MethodChannel('dev.fluttercommunity.plus/package_info');

  setUp(() async {
    messenger.setMockMethodCallHandler(prefs,
        (call) async => call.method == 'getAll' ? <String, Object>{} : true);
    messenger.setMockMethodCallHandler(
        packageInfo,
        (_) async => {
              'appName': 'GuIA',
              'packageName': 'com.guiahn.automotriz',
              'version': '1.0.8',
              'buildNumber': '10',
              'buildSignature': '',
            });
    await Upgrader.clearSavedSettings();
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(prefs, null);
    messenger.setMockMethodCallHandler(packageInfo, null);
  });

  AppUpdateService serviceFor(_Store store) {
    final service = AppUpdateService(
      storeController: UpgraderStoreController(
        onAndroid: () => store,
        oniOS: () => store,
        onMacOS: () => store,
      ),
    );
    addTearDown(service.dispose);
    return service;
  }

  test(
      'compares numeric versions, suppresses current versions and respects reminder interval',
      () async {
    final store = _Store();
    final service = serviceFor(store);
    expect(await service.initialize(), isTrue);
    expect(service.shouldDisplayUpgrade(), isTrue); // 1.0.10 > 1.0.8
    expect(service.blocked(), isFalse);
    await service.saveLastAlerted();
    expect(service.shouldDisplayUpgrade(), isFalse);
    store.latest = '1.0.8';
    await service.updateVersionInfo();
    expect(service.shouldDisplayUpgrade(), isFalse);
    store.latest = '1.0.7';
    await service.updateVersionInfo();
    expect(service.shouldDisplayUpgrade(), isFalse);
  });

  test(
      'remote minimum and critical flags remain optional and respect reminders',
      () async {
    final store = _Store()
      ..minimum = '1.0.9'
      ..critical = true;
    final service = serviceFor(store);
    await service.initialize();
    expect(service.belowMinAppVersion(), isTrue);
    expect(service.versionInfo?.isCriticalUpdate, isTrue);
    expect(service.blocked(), isFalse);
    expect(service.shouldDisplayUpgrade(), isTrue);
    await service.saveLastAlerted();
    expect(service.shouldDisplayUpgrade(), isFalse);
  });

  test('store outages on startup and resume do not escape to the app',
      () async {
    final service = serviceFor(_Store()..fail = true);
    expect(await service.initialize(), isTrue);
    expect(service.shouldDisplayUpgrade(), isFalse);
    expect(await service.updateVersionInfo(), isNull);
    expect(await service.openStore(), isFalse);
  });
}
