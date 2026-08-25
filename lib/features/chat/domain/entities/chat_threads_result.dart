import 'chat_thread.dart';

class ChatThreadsResult {
  final List<ChatThread> threads;
  final Map<String, int> counts;

  const ChatThreadsResult({
    required this.threads,
    this.counts = const {},
  });
}
