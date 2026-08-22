import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/providers/cache_for.dart';

void main() {
  test('retains an auto-disposed value between short listener gaps', () async {
    var loads = 0;
    final cachedProvider = FutureProvider.autoDispose<int>((ref) async {
      ref.cacheFor(const Duration(minutes: 1));
      return ++loads;
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final firstVisit = container.listen(
      cachedProvider,
      (_, __) {},
      fireImmediately: true,
    );
    expect(await container.read(cachedProvider.future), 1);
    firstVisit.close();
    await Future<void>.delayed(Duration.zero);

    final secondVisit = container.listen(
      cachedProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(secondVisit.close);

    expect(await container.read(cachedProvider.future), 1);
    expect(loads, 1);
  });
}
