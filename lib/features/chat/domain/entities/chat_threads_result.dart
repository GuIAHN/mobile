import 'chat_thread.dart';

class ChatThreadsResult {
  final List<ChatThread> threads;
  final Map<String, int> counts;
  final int total;

  const ChatThreadsResult({
    required this.threads,
    this.counts = const {},
    this.total = 0,
  });
}
