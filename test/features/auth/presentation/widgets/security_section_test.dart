import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/security_section.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open-change-password')));
  await tester.pumpAndSettle();
}

Future<void> _fillForm(
  WidgetTester tester, {
  required String current,
  required String next,
  required String confirm,
}) async {
  await tester.enterText(
      find.byKey(const Key('current-password-field')), current);
  await tester.enterText(find.byKey(const Key('new-password-field')), next);
  await tester.enterText(
      find.byKey(const Key('confirm-password-field')), confirm);
  await tester.pump();
}

void main() {
  late _MockAuthRepository repository;
  late bool sessionClosed;

  setUp(() {
    repository = _MockAuthRepository();
    sessionClosed = false;
  });

  Widget buildApp({
    TextScaler textScaler = TextScaler.noScaling,
    bool disableAnimations = false,
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        passwordChangeSessionHandlerProvider.overrideWithValue(() async {
          sessionClosed = true;
        }),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: textScaler,
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
        home: const Scaffold(
          body: SingleChildScrollView(child: SecuritySection()),
        ),
      ),
    );
  }

  testWidgets('opens the change password sheet on tap', (tester) async {
    await tester.pumpWidget(buildApp());
    await _openSheet(tester);

    expect(find.text('Cambiar contraseña'), findsWidgets);
    expect(find.byKey(const Key('current-password-field')), findsOneWidget);

    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('save-change-password')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('shows validation errors for short or mismatched passwords',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await _openSheet(tester);

    await _fillForm(tester, current: 'oldpass1', next: '123', confirm: '123');
    await tester.tap(find.byKey(const Key('save-change-password')));
    await tester.pumpAndSettle();

    expect(find.text('Debe tener al menos 6 caracteres'), findsOneWidget);
    verifyNever(() => repository.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ));

    await _fillForm(
      tester,
      current: 'oldpass1',
      next: 'newpass1',
      confirm: 'different1',
    );
    await tester.tap(find.byKey(const Key('save-change-password')));
    await tester.pumpAndSettle();

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
  });

  testWidgets('submits and closes the sheet on success', (tester) async {
    when(() => repository.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) async => const Right(null));

    await tester.pumpWidget(buildApp());
    await _openSheet(tester);

    await _fillForm(
      tester,
      current: 'oldpass1',
      next: 'newpass1',
      confirm: 'newpass1',
    );
    await tester.tap(find.byKey(const Key('save-change-password')));
    await tester.pumpAndSettle();

    verify(() => repository.changePassword(
          currentPassword: 'oldpass1',
          newPassword: 'newpass1',
        )).called(1);
    expect(sessionClosed, isTrue);
    expect(find.byKey(const Key('current-password-field')), findsNothing);
  });

  testWidgets('shows loading feedback and disables both actions while saving',
      (tester) async {
    final completer = Completer<Either<Failure, void>>();
    when(() => repository.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer((_) => completer.future);

    await tester.pumpWidget(buildApp());
    await _openSheet(tester);
    await _fillForm(
      tester,
      current: 'oldpass1',
      next: 'newpass1',
      confirm: 'newpass1',
    );

    await tester.tap(find.byKey(const Key('save-change-password')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const Key('save-change-password')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.ancestor(
              of: find.text('Cancelar'),
              matching: find.byType(OutlinedButton),
            ),
          )
          .onPressed,
      isNull,
    );

    completer.complete(const Right(null));
    await tester.pumpAndSettle();
    expect(sessionClosed, isTrue);
  });

  testWidgets('keeps the sheet open and shows the server error on failure',
      (tester) async {
    when(() => repository.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        )).thenAnswer(
      (_) async => const Left(
        UnauthorizedFailure(message: 'Contraseña actual incorrecta.'),
      ),
    );

    await tester.pumpWidget(buildApp());
    await _openSheet(tester);

    await _fillForm(
      tester,
      current: 'wrongpass',
      next: 'newpass1',
      confirm: 'newpass1',
    );
    await tester.tap(find.byKey(const Key('save-change-password')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('change-password-error')), findsOneWidget);
    expect(find.text('Contraseña actual incorrecta.'), findsOneWidget);
    expect(find.byKey(const Key('current-password-field')), findsOneWidget);
  });

  testWidgets(
      'supports small and large phones with large text and touch targets',
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
      await _openSheet(tester);

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byTooltip('Mostrar contraseña').first).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byKey(const Key('save-change-password'))).height,
        greaterThanOrEqualTo(48),
      );

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
    }
  });
}
