import '../../../../core/domain/entities/paged_result.dart';
import 'chat_thread.dart';

class ChatThreadsResult extends PagedResult<ChatThread> {
  const ChatThreadsResult({
    required List<ChatThread> threads,
    super.counts,
    super.page,
    super.pageSize,
    super.total,
  }) : super(items: threads);

  List<ChatThread> get threads => items;
}
