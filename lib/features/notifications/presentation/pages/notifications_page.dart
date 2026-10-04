import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/user_notification.dart';
import '../providers/notifications_providers.dart';
import '../providers/notifications_state.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_card_skeleton.dart';
import '../widgets/notification_detail_sheet.dart';
import '../../services/notification_route_resolver.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final ScrollController _scrollController = ScrollController();
  late final ProviderSubscription<NotificationsState> _stateSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearTheEnd);
    _stateSubscription = ref.listenManual<NotificationsState>(
      notificationsProvider,
      (previous, next) {
        final error = next.actionError;
        if (error == null || error == previous?.actionError) return;

        NotificationService.error(ref, error);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(notificationsProvider.notifier).clearActionError();
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _stateSubscription.close();
    _scrollController
      ..removeListener(_loadMoreNearTheEnd)
      ..dispose();
    super.dispose();
  }

  void _loadMoreNearTheEnd() {
    if (_scrollController.position.extentAfter < 240) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  Future<void> _openNotification(UserNotification notification) async {
    final notifier = ref.read(notificationsProvider.notifier);
    final markRead = notifier.markRead(notification.id);
    final destination = NotificationRouteResolver.resolve(
      type: notification.type,
      data: notification.data,
    );

    if (destination == RouteNames.notifications) {
      await showNotificationDetailSheet(
        context,
        notification: notification,
      );
    } else {
      unawaited(context.push<void>(destination));
    }

    final wasMarked = await markRead;
    if (wasMarked && mounted) {
      await notifier.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _NotificationsHeader(state: state),
            Expanded(child: _buildContent(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(NotificationsState state) {
    if (state.isInitialLoading) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl2,
          AppSpacing.md,
          AppSpacing.xl2,
          AppSpacing.xl2,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) => const NotificationCardSkeleton(),
      );
    }

    if (state.initialError != null) {
      return _NotificationsErrorState(
        message: state.initialError!,
        onRetry: ref.read(notificationsProvider.notifier).loadInitial,
      );
    }

    if (state.items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: ref.read(notificationsProvider.notifier).refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
          children: const [
            SizedBox(height: AppSpacing.xl4),
            EmptyState(
              icon: AppIcons.notification,
              title: 'Estás al día',
              subtitle: 'No tienes notificaciones sin leer.',
            ),
          ],
        ),
      );
    }

    final itemCount = state.items.length + (state.isLoadingMore ? 1 : 0);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: ref.read(notificationsProvider.notifier).refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl2,
          AppSpacing.md,
          AppSpacing.xl2,
          AppSpacing.xl3,
        ),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: SizedBox.square(
                  dimension: AppSpacing.iconMd,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          }

          final notification = state.items[index];
          return NotificationCard(
            notification: notification,
            isMarking: state.markingIds.contains(notification.id),
            onTap: () => _openNotification(notification),
          );
        },
      ),
    );
  }
}

class _NotificationsHeader extends ConsumerWidget {
  const _NotificationsHeader({required this.state});

  final NotificationsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl2,
        AppSpacing.sm,
        AppSpacing.xl2,
        0,
      ),
      child: Column(
        children: [
          SizedBox(
            height: AppSpacing.buttonHeightMd,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    button: true,
                    label: 'Volver',
                    excludeSemantics: true,
                    child: SizedBox.square(
                      key: const Key('notifications-back-button'),
                      dimension: AppSpacing.buttonHeightMd,
                      child: IconButton(
                        onPressed: Navigator.of(context).maybePop,
                        tooltip: 'Volver',
                        icon: const AppLineIcon(
                          AppIcons.back,
                          size: AppIconSize.action,
                        ),
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl5,
                  ),
                  child: Text(
                    'Notificaciones',
                    style: AppTypography.h1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          if (!state.isInitialLoading && state.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                children: [
                  Text(
                    state.items.length == 1
                        ? '1 pendiente'
                        : '${state.items.length} pendientes',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textMeta,
                    ),
                  ),
                  Semantics(
                    button: true,
                    enabled: !state.isMarkingAll,
                    label: 'Marcar todas las notificaciones como leídas',
                    excludeSemantics: true,
                    child: SizedBox(
                      key: const Key('notifications-mark-all-button'),
                      height: AppSpacing.buttonHeightMd,
                      child: TextButton(
                        onPressed: state.isMarkingAll
                            ? null
                            : ref
                                .read(notificationsProvider.notifier)
                                .markAllRead,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryInk,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                        ),
                        child: state.isMarkingAll
                            ? const SizedBox.square(
                                dimension: AppSpacing.xl,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              )
                            : Text(
                                'Marcar todas',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.primaryInk,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationsErrorState extends StatelessWidget {
  const _NotificationsErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.cloudError,
              size: AppIconSize.hero,
              color: AppColors.errorInk,
            ),
            const SizedBox(height: AppSpacing.xl2),
            Text(
              'Algo salió mal',
              style: AppTypography.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl2),
            Semantics(
              button: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.buttonHeightMd,
                ),
                child: TextButton.icon(
                  onPressed: onRetry,
                  icon: const AppLineIcon(
                    AppIcons.retry,
                    size: AppIconSize.action,
                  ),
                  label: Text('Reintentar', style: AppTypography.label),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
