import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/account_status.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/entities/user.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/register_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_state.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/account_deletion_section.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _ActionAuthNotifier extends AuthNotifier {
  _ActionAuthNotifier({
    required User user,
    this.onDelete,
    this.onRestore,
  }) : super(
          loginUseCase: LoginUseCase(_MockAuthRepository()),
          registerUseCase: RegisterUseCase(_MockAuthRepository()),
          updateProfileUseCase: UpdateProfileUseCase(_MockAuthRepository()),
          uploadAvatarUseCase: UploadAvatarUseCase(_MockAuthRepository()),
          authRepository: _MockAuthRepository(),
          secureStorage: _MockSecureStorage(),
        ) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  final Future<Failure?> Function(String? password)? onDelete;
  final Future<Failure?> Function()? onRestore;

  @override
  Future<void> checkAuthStatus() async {}

  @override
  Future<Failure?> requestAccountDeletion({String? password}) {
    return onDelete?.call(password) ?? Future.value(null);
  }

  @override
  Future<Failure?> restoreAccount() {
    return onRestore?.call() ?? Future.value(null);
  }
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required User user,
  required _ActionAuthNotifier notifier,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authProvider.overrideWith((ref) => notifier)],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AccountDeletionSection(user: user),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const passwordUser = User(
    id: 'user-1',
    email: 'driver@example.com',
    name: 'Driver',
  );
  const socialUser = User(
    id: 'user-2',
    email: 'social@example.com',
    name: 'Social Driver',
    authProvider: 'google',
  );

  testWidgets('requires current password and the exact DELETE confirmation',
      (tester) async {
    String? submittedPassword;
    final notifier = _ActionAuthNotifier(
      user: passwordUser,
      onDelete: (password) async {
        submittedPassword = password;
        return null;
      },
    );
    await _pumpSection(tester, user: passwordUser, notifier: notifier);

    await tester.tap(find.byKey(const Key('request-account-deletion')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('delete-account-password-field')), findsOneWidget);
    expect(find.byKey(const Key('delete-account-confirmation-field')),
        findsOneWidget);
    var confirmButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('confirm-account-deletion')),
    );
    expect(confirmButton.onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('delete-account-password-field')),
      'current-password',
    );
    await tester.enterText(
      find.byKey(const Key('delete-account-confirmation-field')),
      'DELETE',
    );
    await tester.pump();

    confirmButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('confirm-account-deletion')),
    );
    expect(confirmButton.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('confirm-account-deletion')));
    await tester.pumpAndSettle();

    expect(submittedPassword, 'current-password');
    expect(find.byKey(const Key('delete-account-confirmation-field')),
        findsNothing);
  });

  testWidgets('social-only accounts do not ask for a password', (tester) async {
    String? submittedPassword = 'not-called';
    final notifier = _ActionAuthNotifier(
      user: socialUser,
      onDelete: (password) async {
        submittedPassword = password;
        return null;
      },
    );
    await _pumpSection(tester, user: socialUser, notifier: notifier);

    await tester.tap(find.byKey(const Key('request-account-deletion')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('delete-account-password-field')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('delete-account-confirmation-field')),
      'DELETE',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-account-deletion')));
    await tester.pumpAndSettle();

    expect(submittedPassword, isNull);
  });

  testWidgets('keeps a backend failure visible inside the confirmation sheet',
      (tester) async {
    final notifier = _ActionAuthNotifier(
      user: passwordUser,
      onDelete: (_) async => const ServerFailure(
        message: 'La contraseña actual no es correcta.',
        code: 401,
      ),
    );
    await _pumpSection(tester, user: passwordUser, notifier: notifier);

    await tester.tap(find.byKey(const Key('request-account-deletion')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('delete-account-password-field')),
      'wrong-password',
    );
    await tester.enterText(
      find.byKey(const Key('delete-account-confirmation-field')),
      'DELETE',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-account-deletion')));
    await tester.pumpAndSettle();

    expect(find.text('La contraseña actual no es correcta.'), findsOneWidget);
    expect(
        find.bySemanticsLabel('Error al eliminar la cuenta'), findsOneWidget);
  });

  testWidgets('disables deletion actions while the request is running',
      (tester) async {
    final completion = Completer<Failure?>();
    final notifier = _ActionAuthNotifier(
      user: socialUser,
      onDelete: (_) => completion.future,
    );
    await _pumpSection(tester, user: socialUser, notifier: notifier);

    await tester.tap(find.byKey(const Key('request-account-deletion')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('delete-account-confirmation-field')),
      'DELETE',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-account-deletion')));
    await tester.pump();

    expect(find.byKey(const Key('account-deletion-progress')), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('confirm-account-deletion')),
    );
    expect(button.onPressed, isNull);

    completion.complete(null);
    await tester.pumpAndSettle();
  });

  testWidgets('pending account shows purge date and restores through notifier',
      (tester) async {
    var restores = 0;
    final pendingUser = User(
      id: 'user-3',
      email: 'pending@example.com',
      name: 'Pending Driver',
      accountStatus: AccountStatus.pendingDeletion,
      deletionScheduledAt: DateTime(2026, 10, 9),
    );
    final notifier = _ActionAuthNotifier(
      user: pendingUser,
      onRestore: () async {
        restores += 1;
        return null;
      },
    );
    await _pumpSection(tester, user: pendingUser, notifier: notifier);

    expect(find.text('Cuenta programada para eliminación'), findsOneWidget);
    expect(find.textContaining('9'), findsWidgets);
    await tester.tap(find.byKey(const Key('restore-account')));
    await tester.pumpAndSettle();

    expect(restores, 1);
  });

  testWidgets('fits small phones with enlarged text and disabled animations',
      (tester) async {
    final notifier = _ActionAuthNotifier(user: socialUser);
    await _pumpSection(
      tester,
      user: socialUser,
      notifier: notifier,
      size: const Size(320, 568),
      textScale: 2,
    );

    await tester.tap(find.byKey(const Key('request-account-deletion')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const Key('confirm-account-deletion'))).height,
      greaterThanOrEqualTo(48),
    );
  });
}
