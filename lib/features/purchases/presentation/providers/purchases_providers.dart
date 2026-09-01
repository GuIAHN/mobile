import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/session/session_generation_provider.dart';
import '../../data/datasources/purchases_remote_datasource.dart';
import '../../data/repositories/purchases_repository_impl.dart';
import '../../domain/entities/consumer_purchase.dart';
import '../../domain/entities/purchases_result.dart';
import '../../domain/repositories/purchases_repository.dart';
import '../../domain/usecases/get_consumer_purchases_usecase.dart';

final purchasesRemoteDataSourceProvider = Provider<PurchasesRemoteDataSource>(
  (ref) => PurchasesRemoteDataSource(ref.watch(dioClientProvider)),
);

final purchasesRepositoryProvider = Provider<PurchasesRepository>(
  (ref) => PurchasesRepositoryImpl(
    ref.watch(purchasesRemoteDataSourceProvider),
  ),
);

final getConsumerPurchasesUseCaseProvider =
    Provider<GetConsumerPurchasesUseCase>(
  (ref) => GetConsumerPurchasesUseCase(
    ref.watch(purchasesRepositoryProvider),
  ),
);

final purchaseFilterProvider = StateProvider<PurchaseFilter>((ref) {
  ref.watch(sessionGenerationProvider);
  return PurchaseFilter.all;
});

final _purchasesRevisionProvider =
    StateNotifierProvider<_PurchasesRevisionNotifier, int>((ref) {
  ref.watch(sessionGenerationProvider);
  return _PurchasesRevisionNotifier(ref.watch(socketServiceProvider));
});

class _PurchasesRevisionNotifier extends StateNotifier<int> {
  _PurchasesRevisionNotifier(SocketService socketService) : super(0) {
    _subscriptions = [
      socketService.onOfferUpdated.listen((_) => state++),
      socketService.onReconnect.listen((_) => state++),
    ];
  }

  late final List<StreamSubscription<dynamic>> _subscriptions;

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

final consumerPurchasesProvider = FutureProvider<PurchasesResult>((ref) async {
  ref.watch(sessionGenerationProvider);
  ref.watch(_purchasesRevisionProvider);
  final filter = ref.watch(purchaseFilterProvider);
  final useCase = ref.watch(getConsumerPurchasesUseCaseProvider);
  final result = await useCase(filter: filter);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (purchases) => purchases,
  );
});
