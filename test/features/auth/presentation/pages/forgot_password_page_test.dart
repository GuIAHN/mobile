import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _acceptedMessage =
    'Si el correo está registrado, recibirás un código de verificación.';

Finder primaryButton(Key key) => find.descendant(
      of: find.byKey(key),
      matching: find.byType(ElevatedButton),
    );

Future<void> tapPrimaryButton(WidgetTester tester, Key key) async {
  final wrapper = find.byKey(key);
  await tester.ensureVisible(wrapper);
  await tester.pump();
  await tester.tap(primaryButton(key));
}

void main() {
  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
  });

  Widget buildApp({
    TextScaler textScaler = TextScaler.noScaling,
    bool disableAnimations = false,
  }) {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: textScaler,
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
        home: const ForgotPasswordPage(),
      ),
    );
  }

  Future<void> requestCode(WidgetTester tester) async {
    when(() => repository.forgotPassword(email: any(named: 'email')))
        .thenAnswer((_) async => const Right(_acceptedMessage));
    await tester.enterText(
      find.byKey(const Key('recovery-email-field')),
      'USER@Example.com ',
    );
    await tester.pump();
    await tapPrimaryButton(tester, const Key('request-reset-code'));
    await tester.pumpAndSettle();
  }

  testWidgets('requests a reset code and advances without exposing accounts',
      (tester) async {
    await tester.pumpWidget(buildApp());

    expect(
      tester
          .widget<ElevatedButton>(
            primaryButton(const Key('request-reset-code')),
          )
          .onPressed,
      isNull,
    );

    await requestCode(tester);

    verify(() => repository.forgotPassword(email: 'user@example.com'))
        .called(1);
    expect(find.text('Revisa tu correo'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.byKey(const Key('reset-code-field')), findsOneWidget);
    expect(find.text(_acceptedMessage), findsOneWidget);
  });

  testWidgets('starts step two at the top with back navigation visible',
      (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildApp());
    await requestCode(tester);

    final scrollable = tester.widget<SingleChildScrollView>(
      find.byKey(const Key('password-recovery-scroll')),
    );
    expect(scrollable.controller!.offset, 0);
    expect(find.byKey(const Key('recovery-back')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('recovery-back'))).dy,
      lessThanOrEqualTo(24),
    );
    expect(find.text('Revisa tu correo'), findsOneWidget);
  });

  testWidgets('submits the code and new password then shows success',
      (tester) async {
    when(() => repository.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer(
      (_) async => const Right('Contraseña actualizada exitosamente'),
    );
    await tester.pumpWidget(buildApp());
    await requestCode(tester);

    await tester.enterText(
      find.byKey(const Key('reset-code-field')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const Key('reset-new-password-field')),
      'newpass1',
    );
    await tester.enterText(
      find.byKey(const Key('reset-confirm-password-field')),
      'newpass1',
    );
    await tester.pump();
    await tapPrimaryButton(tester, const Key('confirm-password-reset'));
    await tester.pumpAndSettle();

    verify(() => repository.resetPassword(
          email: 'user@example.com',
          code: '123456',
          newPassword: 'newpass1',
        )).called(1);
    expect(find.byKey(const Key('password-reset-success')), findsOneWidget);
    expect(find.text('Contraseña actualizada'), findsOneWidget);
  });

  testWidgets('keeps the reset form open when the code is invalid',
      (tester) async {
    when(() => repository.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer(
      (_) async => const Left(
        ValidationFailure(message: 'Código inválido o expirado'),
      ),
    );
    await tester.pumpWidget(buildApp());
    await requestCode(tester);

    await tester.enterText(
      find.byKey(const Key('reset-code-field')),
      '999999',
    );
    await tester.enterText(
      find.byKey(const Key('reset-new-password-field')),
      'newpass1',
    );
    await tester.enterText(
      find.byKey(const Key('reset-confirm-password-field')),
      'newpass1',
    );
    await tester.pump();
    await tapPrimaryButton(tester, const Key('confirm-password-reset'));
    await tester.pumpAndSettle();

    expect(find.text('Código inválido o expirado'), findsOneWidget);
    expect(find.byKey(const Key('reset-code-field')), findsOneWidget);
  });

  testWidgets('shows loading feedback and disables submission', (tester) async {
    final completer = Completer<Either<Failure, String>>();
    when(() => repository.forgotPassword(email: any(named: 'email')))
        .thenAnswer((_) => completer.future);
    await tester.pumpWidget(buildApp());
    await tester.enterText(
      find.byKey(const Key('recovery-email-field')),
      'user@example.com',
    );
    await tester.pump();
    await tapPrimaryButton(tester, const Key('request-reset-code'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            primaryButton(const Key('request-reset-code')),
          )
          .onPressed,
      isNull,
    );

    completer.complete(const Right(_acceptedMessage));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reset-code-field')), findsOneWidget);
  });

  testWidgets('fits small and large phones with large text and reduced motion',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;

    for (final size in const [Size(320, 568), Size(430, 932)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        buildApp(
          textScaler: const TextScaler.linear(2),
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const Key('recovery-back'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byKey(const Key('request-reset-code'))).height,
        greaterThanOrEqualTo(48),
      );
    }
  });
}
