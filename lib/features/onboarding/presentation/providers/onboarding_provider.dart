import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage.dart';

/// Provider que gestiona el estado del onboarding (página actual).
final onboardingPageProvider =
    StateNotifierProvider<OnboardingPageNotifier, int>((ref) {
  return OnboardingPageNotifier(ref.read(secureStorageProvider));
});

/// Notifier para la página actual del onboarding.
class OnboardingPageNotifier extends StateNotifier<int> {
  final SecureStorage _storage;

  OnboardingPageNotifier(this._storage) : super(0);

  /// Cambia la página actual.
  void setPage(int page) => state = page;

  /// Marca el onboarding como visto y persiste el flag.
  Future<void> markAsSeen() async {
    await _storage.markOnboardingSeen();
  }
}
