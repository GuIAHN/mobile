import 'package:dartz/dartz.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/error_mapper.dart';
import '../../domain/entities/chat_threads_result.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final UserRole Function() getCurrentRole;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.getCurrentRole,
  });

  @override
  Future<Either<Failure, ChatThreadsResult>> getChatThreads({
    UserRole? role,
    String? statusFilter,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final resolvedRole = role ?? getCurrentRole();
      final result = await remoteDataSource.getChatThreads(
        resolvedRole,
        statusFilter: statusFilter,
        page: page,
        pageSize: pageSize,
      );
      return Right(result);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, List<ChatConversation>>> getConversations(
      String threadId) async {
    try {
      final role = getCurrentRole();
      final conversations =
          await remoteDataSource.getConversations(threadId, role);
      return Right(conversations);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(
      String conversationId) async {
    try {
      final role = getCurrentRole();
      final messages = await remoteDataSource.getMessages(conversationId, role);
      return Right(messages);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, ChatMessage?>> getLatestMessage(
      String conversationId) async {
    try {
      final message = await remoteDataSource.getLatestMessage(conversationId);
      return Right(message);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, ChatConversation>> createQuote({
    required String threadId,
    String? searchMatchId,
    double? price,
    double? deliveryCost,
    String? brand,
    String? photoPath,
  }) async {
    try {
      final conversation = await remoteDataSource.createQuote(
        threadId: threadId,
        searchMatchId: searchMatchId,
        price: price,
        deliveryCost: deliveryCost,
        brand: brand,
        photoPath: photoPath,
      );
      return Right(conversation);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, void>> quoteOffer({
    required String offerId,
    required double price,
    required bool updateDeliveryCost,
    double? deliveryCost,
    String? brand,
    String? photoPath,
  }) async {
    try {
      await remoteDataSource.quoteOffer(
        offerId: offerId,
        price: price,
        updateDeliveryCost: updateDeliveryCost,
        deliveryCost: deliveryCost,
        brand: brand,
        photoPath: photoPath,
      );
      return const Right(null);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, String>> startChatFromOffer(String offerId) async {
    try {
      final conversationId = await remoteDataSource.startChatFromOffer(offerId);
      return Right(conversationId);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, List<ChatConversation>>> getMyConversations() async {
    try {
      final conversations = await remoteDataSource.getMyConversations();
      return Right(conversations);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, ChatConversation>> getConversationDetails(
      String conversationId) async {
    try {
      final conversation =
          await remoteDataSource.getConversationDetails(conversationId);
      return Right(conversation);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, void>> buyOffer(String offerId) async {
    try {
      await remoteDataSource.buyOffer(offerId);
      return const Right(null);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, void>> deliverOffer(String offerId) async {
    try {
      await remoteDataSource.deliverOffer(offerId);
      return const Right(null);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, void>> cancelOffer(
    String offerId, {
    String? reason,
  }) async {
    try {
      await remoteDataSource.cancelOffer(offerId, reason: reason);
      return const Right(null);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, void>> declineMatch(
    String searchMatchId,
    String reason,
  ) async {
    try {
      await remoteDataSource.declineMatch(searchMatchId, reason);
      return const Right(null);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, void>> undoDecline(String searchMatchId) async {
    try {
      await remoteDataSource.undoDecline(searchMatchId);
      return const Right(null);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String conversationId) async {
    try {
      await remoteDataSource.markAsRead(conversationId);
      return const Right(null);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }
}
