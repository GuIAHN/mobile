import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/current_user_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../../shared/layout/bottom_navigation_insets.dart';
import '../../domain/entities/chat_conversation.dart';
import '../providers/chat_providers.dart';
import '../widgets/store_chat_card.dart';

/// Bandeja transversal de conversaciones.
///
/// No contiene solicitudes ni filtros comerciales: consumidor y tienda ven
/// aquí solamente chats que ya existen en `GET /conversations/me`.
class ConversationsInboxPage extends ConsumerStatefulWidget {
  const ConversationsInboxPage({super.key});

  @override
  ConsumerState<ConversationsInboxPage> createState() =>
      _ConversationsInboxPageState();
}

class _ConversationsInboxPageState
    extends ConsumerState<ConversationsInboxPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatConversation> _filter(List<ChatConversation> conversations) {
    final visibleConversations = conversations
        .where((conversation) => !conversation.isCompletedAfterReview);
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return visibleConversations.toList();

    return visibleConversations.where((conversation) {
      return conversation.participantName.toLowerCase().contains(query) ||
          (conversation.spareBrand?.toLowerCase().contains(query) ?? false) ||
          conversation.lastMessage.toLowerCase().contains(query) ||
          (conversation.note?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentRoleProvider);
    final conversationsAsync = ref.watch(myConversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ConversationsHeader(
              controller: _searchController,
              query: _query,
              enabled: !conversationsAsync.isLoading,
              onChanged: (value) => setState(() => _query = value),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
            Expanded(
              child: conversationsAsync.when(
                loading: _buildLoading,
                error: (error, _) => _ConversationsError(
                  onRetry: () => ref.invalidate(myConversationsProvider),
                ),
                data: (conversations) => _buildList(
                  conversations,
                  consumerPerspective: !role.isStore,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        bottomNavigationContentInset(context) + 24,
      ),
      itemCount: 4,
      itemBuilder: (_, index) => StaggeredEntrance(
        index: index,
        child: const ThreadCardSkeleton(isStore: true),
      ),
    );
  }

  Widget _buildList(
    List<ChatConversation> conversations, {
    required bool consumerPerspective,
  }) {
    final filtered = _filter(conversations);

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.refresh(myConversationsProvider.future),
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.only(
            bottom: bottomNavigationContentInset(context) + 24,
          ),
          children: [
            const SizedBox(height: 80),
            EmptyState(
              title:
                  _query.isNotEmpty ? 'Sin resultados' : 'Aún no tienes chats',
              subtitle: _query.isNotEmpty
                  ? 'No encontramos conversaciones para "$_query".'
                  : 'Cuando inicies una conversación, aparecerá aquí.',
              icon: _query.isNotEmpty ? AppIcons.searchEmpty : AppIcons.message,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(myConversationsProvider.future),
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          bottomNavigationContentInset(context) + 24,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final conversation = filtered[index];
          return StaggeredEntrance(
            key: ValueKey(
              'conversation-${conversation.realtimeConversationId}',
            ),
            index: index,
            child: RealtimeStoreChatCard(
              conversation: conversation,
              consumerPerspective: consumerPerspective,
              onTap: () => context.push(
                RouteNames.chatConversationPath(conversation.id),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConversationsHeader extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _ConversationsHeader({
    required this.controller,
    required this.query,
    required this.enabled,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.6),
        ),
      ),
      child: Container(
        key: const Key('conversations-search-bar'),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.only(left: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const AppLineIcon(
              AppIcons.search,
              color: AppColors.textSecondary,
              size: AppIconSize.action,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                onChanged: onChanged,
                style: AppTypography.body,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Buscar una conversación...',
                  hintStyle: AppTypography.body.copyWith(
                    color: AppColors.textPlaceholder,
                  ),
                ),
              ),
            ),
            if (query.isNotEmpty)
              SizedBox.square(
                dimension: 48,
                child: IconButton(
                  onPressed: onClear,
                  tooltip: 'Limpiar búsqueda',
                  icon: const AppLineIcon(
                    AppIcons.close,
                    color: AppColors.textSecondary,
                    size: AppIconSize.inline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConversationsError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ConversationsError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLineIcon(
              AppIcons.cloudError,
              color: AppColors.error,
              size: AppIconSize.feature,
            ),
            const SizedBox(height: 12),
            Text(
              'No pudimos cargar tus chats',
              textAlign: TextAlign.center,
              style: AppTypography.title,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
