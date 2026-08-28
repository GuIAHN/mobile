import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/notifications/notification_provider.dart';
import 'package:guiautomotriz_mobile/core/notifications/notification_type.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/providers/current_user_provider.dart';
import 'package:guiautomotriz_mobile/core/services/location_service.dart';
import 'package:guiautomotriz_mobile/core/session/session_state_coordinator.dart';
import 'package:guiautomotriz_mobile/core/session/session_generation_provider.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/social_registration_state.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/providers/chat_providers.dart';

final _resetTriggerProvider = StateProvider<int>((ref) => 0);

final _resetSessionHarnessProvider = Provider<void>((ref) {
  ref.listen<int>(_resetTriggerProvider, (_, __) {
    resetSessionScopedState(ref);
  });
});

void main() {
  test('session reset removes account filters, notifications and auth drafts',
      () {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(null),
        currentRoleProvider.overrideWithValue(UserRole.consumer),
      ],
    );
    addTearDown(container.dispose);

    container.read(storeStatusFilterProvider.notifier).state = 'QUOTED';
    container.read(consumerStatusFilterProvider.notifier).state = 'BOUGHT';
    container.read(isLocationSharedProvider.notifier).state = true;
    container.read(socialRegistrationProvider.notifier).setData(
          idToken: 'old-account-token',
          provider: 'GOOGLE',
          email: 'old@account.test',
          name: 'Old Account',
        );
    container.read(notificationProvider.notifier).show(
          type: NotificationType.info,
          message: 'Solicitud de la cuenta anterior',
        );

    expect(container.read(notificationProvider), hasLength(1));

    container.read(_resetSessionHarnessProvider);
    container.read(_resetTriggerProvider.notifier).state += 1;

    expect(container.read(storeStatusFilterProvider), 'PENDING');
    expect(container.read(consumerStatusFilterProvider), 'OPEN');
    expect(container.read(isLocationSharedProvider), isFalse);
    expect(container.read(socialRegistrationProvider), isNull);
    expect(container.read(notificationProvider), isEmpty);
  });

  test('a new session generation rebuilds account-scoped filters', () {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(null),
        currentRoleProvider.overrideWithValue(UserRole.consumer),
      ],
    );
    addTearDown(container.dispose);

    container.read(storeStatusFilterProvider.notifier).state = 'QUOTED';
    container.read(consumerStatusFilterProvider.notifier).state = 'BOUGHT';

    container.read(sessionGenerationProvider.notifier).state += 1;

    expect(container.read(storeStatusFilterProvider), 'PENDING');
    expect(container.read(consumerStatusFilterProvider), 'OPEN');
  });
}
