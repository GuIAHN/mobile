import 'package:dartz/dartz.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/error_mapper.dart';
import '../../domain/entities/chat_thread.dart';
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
  Future<Either<Failure, List<ChatThread>>> getChatThreads() async {
    try {
      final role = getCurrentRole();
      final threads = await remoteDataSource.getChatThreads(role);
      return Right(threads);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, List<ChatConversation>>> getConversations(String threadId) async {
    try {
      final role = getCurrentRole();
      final conversations = await remoteDataSource.getConversations(threadId, role);
      return Right(conversations);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(String conversationId) async {
    try {
      final role = getCurrentRole();
      final messages = await remoteDataSource.getMessages(conversationId, role);
      return Right(messages);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage(String conversationId, String content) async {
    try {
      final role = getCurrentRole();
      final message = await remoteDataSource.sendMessage(conversationId, content, role);
      return Right(message);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, ChatConversation>> createQuote({
    required String threadId,
    required bool isFixedPrice,
    double? price,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final conversation = await remoteDataSource.createQuote(
        threadId: threadId,
        isFixedPrice: isFixedPrice,
        price: price,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
      return Right(conversation);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }
}
