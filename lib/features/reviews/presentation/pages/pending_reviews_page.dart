import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/pending_review.dart';
import '../../domain/entities/my_review_status.dart';
import '../../domain/entities/review.dart';
import '../../../../core/utils/media_url.dart';
import '../providers/reviews_providers.dart';
import '../widgets/write_review_bottom_sheet.dart';
import '../../../home/presentation/providers/home_providers.dart';

class PendingReviewsPage extends ConsumerWidget {
  const PendingReviewsPage({super.key});

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    PendingReview item,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WriteReviewBottomSheet(
        targetId: item.targetId,
        conversationId: item.conversationId,
        providerName: item.providerName,
        initialStatus: _reviewStatus(item),
      ),
    );
    if (!context.mounted) return;
    if (saved == true) {
      final conversationId = item.conversationId;
      if (conversationId != null) {
        await markStoreReviewHandled(ref, conversationId);
      }
      if (!context.mounted) return;
      ref.read(homeTabProvider.notifier).state = MainNavigationTab.home;
      context.go(RouteNames.home);
    }
  }

  MyReviewStatus _reviewStatus(PendingReview item) {
    final reviewId = item.reviewId;
    final rating = item.reviewRating;
    if (!item.hasReviewed || reviewId == null || rating == null) {
      return const MyReviewStatus(hasReviewed: false);
    }
    return MyReviewStatus(
      hasReviewed: true,
      review: Review(
        id: reviewId,
        authorId: '',
        targetId: item.targetId,
        conversationId: item.conversationId,
        rating: rating,
        comentario: item.reviewComment,
        createdAt: item.eligibleAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        authorName: '',
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingReviewsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text('Reseñas pendientes', style: AppTypography.title),
      ),
      body: SafeArea(
        top: false,
        child: pending.when(
          loading: () => const _PendingLoading(),
          error: (error, _) => _PendingError(
            onRetry: () => ref.invalidate(pendingReviewsProvider),
          ),
          data: (items) => items.isEmpty
              ? const _PendingEmpty()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async =>
                      ref.refresh(pendingReviewsProvider.future),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.xl3,
                    ),
                    children: [
                      Text('Tu experiencia cuenta', style: AppTypography.h1),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Comparte tu experiencia con estos proveedores. La puntuación es obligatoria y el comentario es opcional.',
                        style: AppTypography.bodySm,
                      ),
                      const SizedBox(height: AppSpacing.xl2),
                      for (final item in items) ...[
                        _PendingReviewCard(
                          item: item,
                          onPressed: () => _review(context, ref, item),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _PendingReviewCard extends StatelessWidget {
  final PendingReview item;
  final VoidCallback onPressed;

  const _PendingReviewCard({required this.item, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final photoUrl = resolveMediaUrl(item.providerPhoto);
    return Semantics(
      container: true,
      label: 'Reseña pendiente para ${item.providerName}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipOval(
                  child: SizedBox.square(
                    dimension: 56,
                    child: photoUrl == null
                        ? const ColoredBox(
                            color: AppColors.primaryMuted,
                            child: Icon(
                              Icons.storefront_rounded,
                              color: AppColors.primaryInk,
                            ),
                          )
                        : Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: AppColors.primaryMuted,
                              child: Icon(
                                Icons.storefront_rounded,
                                color: AppColors.primaryInk,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.providerName,
                          style: AppTypography.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.eligibleAt == null
                            ? 'Experiencia pendiente'
                            : 'Disponible desde el ${MaterialLocalizations.of(context).formatShortDate(item.eligibleAt!.toLocal())}',
                        style: AppTypography.meta,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeightMd,
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.star_outline_rounded, size: 20),
                label: Text(
                  item.hasReviewed ? 'EDITAR VALORACIÓN' : 'DEJAR VALORACIÓN',
                  style: AppTypography.label.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingLoading extends StatelessWidget {
  const _PendingLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) => Container(
        height: 152,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _PendingError extends StatelessWidget {
  final VoidCallback onRetry;
  const _PendingError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.lg),
            Text('No pudimos cargar tus reseñas', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            Text('Comprueba tu conexión e inténtalo nuevamente.',
                style: AppTypography.bodySm, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, 48),
                foregroundColor: AppColors.primaryInk,
              ),
              child: Text(
                'Reintentar',
                style: AppTypography.label.copyWith(
                  color: AppColors.primaryInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingEmpty extends ConsumerWidget {
  const _PendingEmpty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 36, color: AppColors.successInk),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Estás al día', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            Text('No tienes reseñas pendientes por ahora.',
                style: AppTypography.bodySm, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl2),
            ElevatedButton(
              onPressed: () {
                ref.read(homeTabProvider.notifier).state =
                    MainNavigationTab.home;
                context.go(RouteNames.home);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(160, 48),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'IR AL INICIO',
                style: AppTypography.label.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
