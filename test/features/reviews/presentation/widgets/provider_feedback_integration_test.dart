import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/my_review_status.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/widgets/provider_feedback_integration.dart';
import 'package:guiautomotriz_mobile/shared/provider_feedback/provider_feedback_scope.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements ReviewsRepository {}

class _Storage extends SecureStorage {
  final contacted = <String>{};

  @override
  Future<bool> hasContactedProvider(String providerId) async =>
      contacted.contains(providerId);

  @override
  Future<void> markProviderContacted(String providerId) async {
    contacted.add(providerId);
  }
}

void main() {
  for (final succeeds in [true, false]) {
    testWidgets('contact result $succeeds preserves review eligibility',
        (tester) async {
      final repository = _Repository();
      final storage = _Storage();
      final results = <bool>[];
      when(() => repository.trackProviderContact('profile-1', 'WHATSAPP'))
          .thenAnswer((_) async => succeeds
              ? const Right<Failure, void>(null)
              : const Left<Failure, void>(ServerFailure(message: 'offline')));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          reviewsRepositoryProvider.overrideWithValue(repository),
          secureStorageProvider.overrideWithValue(storage),
          myReviewProvider.overrideWith(
              (ref, key) async => const MyReviewStatus(hasReviewed: false)),
        ],
        child: MaterialApp(home: ProviderFeedbackIntegration(child: Scaffold(
          body: Builder(builder: (context) {
            final feedback = ProviderFeedbackScope.of(context);
            const target = ProviderFeedbackTarget(
                userId: 'user-1',
                profileId: 'profile-1',
                name: 'Mecánico Centro');
            return Column(children: [
              feedback.buildReviewsButton(target),
              feedback.buildReviewAction(target),
              TextButton(
                onPressed: () async => results.add(await feedback
                    .registerContact(target.profileId, 'WHATSAPP')),
                child: const Text('Registrar contacto'),
              ),
            ]);
          }),
        ))),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Ver reseñas de clientes'), findsOneWidget);
      expect(find.text('DEJAR VALORACIÓN'), findsNothing);
      await tester.tap(find.text('Registrar contacto'));
      await tester.pumpAndSettle();

      expect(results, [succeeds]);
      expect(storage.contacted.contains('profile-1'), succeeds);
      expect(find.text('DEJAR VALORACIÓN'),
          succeeds ? findsOneWidget : findsNothing);
      verify(() => repository.trackProviderContact('profile-1', 'WHATSAPP'))
          .called(1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('contact can finish after leaving the provider page',
      (tester) async {
    final repository = _Repository();
    final storage = _Storage();
    final pending = Completer<Either<Failure, void>>();
    final results = <bool>[];
    when(() => repository.trackProviderContact('profile-1', 'PHONE'))
        .thenAnswer((_) => pending.future);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        reviewsRepositoryProvider.overrideWithValue(repository),
        secureStorageProvider.overrideWithValue(storage),
      ],
      child: MaterialApp(
          home: ProviderFeedbackIntegration(
              child: Scaffold(
                  body: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final feedback = ProviderFeedbackScope.of(context);
            results.add(await feedback.registerContact('profile-1', 'PHONE'));
          },
          child: const Text('Registrar contacto'),
        ),
      )))),
    ));
    await tester.tap(find.text('Registrar contacto'));
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(const Right<Failure, void>(null));
    await tester.pump();
    expect(results, [true]);
    expect(storage.contacted, contains('profile-1'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('purchase feedback retains its offer context', (tester) async {
    final keys = <MyReviewKey>[];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        myReviewProvider.overrideWith((ref, key) async {
          keys.add(key);
          return const MyReviewStatus(hasReviewed: false);
        }),
        hasContactedProviderProvider.overrideWith((ref, id) async => false),
      ],
      child: MaterialApp(
          home: ProviderFeedbackIntegration(
              child: Scaffold(
                  body: Builder(
        builder: (context) =>
            ProviderFeedbackScope.of(context).buildReviewAction(
          const ProviderFeedbackTarget(
              userId: 'store-user',
              profileId: 'store-profile',
              name: 'Repuestos Centro',
              offerId: 'offer-123'),
        ),
      )))),
    ));
    await tester.pumpAndSettle();
    expect(keys, [(targetId: 'store-user', offerId: 'offer-123')]);
    await tester.tap(find.text('DEJAR VALORACIÓN'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cómo fue tu experiencia?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
