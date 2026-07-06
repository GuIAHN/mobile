import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_thread_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/empty_state.dart';

class ChatInboxPage extends ConsumerWidget {
  const ChatInboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(chatThreadsProvider);
    final currentRole = ref.watch(currentRoleProvider);
    final isProvider = currentRole.isProvider;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Mensajería',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: threadsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (err, _) => Center(
          child: Text(
            'Error al cargar chats: $err',
            style: GoogleFonts.hankenGrotesk(color: AppColors.error),
          ),
        ),
        data: (threads) {
          if (threads.isEmpty) {
            return EmptyState(
              title: 'Sin conversaciones',
              subtitle: isProvider
                  ? 'No hay solicitudes activas para cotizar en este momento.'
                  : 'Tus solicitudes de repuesto o servicio aparecerán aquí.',
              icon: Icons.chat_bubble_outline_rounded,
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(chatThreadsProvider.future),
            color: AppColors.primary,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: threads.length,
              itemBuilder: (context, index) {
                final thread = threads[index];
                return ChatThreadCard(
                  thread: thread,
                  showClientName: isProvider,
                  onTap: () async {
                    if (isProvider) {
                      // Check if provider has already responded in this thread
                      final convsAsync = await ref.read(chatConversationsProvider(thread.id).future);
                      if (convsAsync.isNotEmpty) {
                        // Provider already responded -> Go directly to the conversation page
                        final conversation = convsAsync.first;
                        if (context.mounted) {
                          context.push('/chats/${thread.id}/${conversation.id}');
                        }
                      } else {
                        // Provider hasn't responded yet -> Go to thread detail page to view or quote
                        if (context.mounted) {
                          context.push('/chats/${thread.id}');
                        }
                      }
                    } else {
                      // Requester -> Opens list of providers that replied
                      context.push('/chats/${thread.id}');
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
