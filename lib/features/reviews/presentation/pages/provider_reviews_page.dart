import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/widgets/paged_list_body.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/reviews_providers.dart';
import '../widgets/review_card.dart';
import '../widgets/write_review_bottom_sheet.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/staggered_entrance.dart';

class ProviderReviewsPage extends ConsumerWidget {
  final String targetId;
  final String? offerId;
  final bool isOwnProfile;

  const ProviderReviewsPage({
    super.key,
    required this.targetId,
    this.offerId,
    this.isOwnProfile = false,
  });

  void _showWriteReviewBottomSheet(BuildContext context) {
    if (offerId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WriteReviewBottomSheet(
        targetId: targetId,
        offerId: offerId!,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(paginatedReviewsProvider(targetId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isOwnProfile ? 'Reseñas recibidas' : 'Reseñas',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      floatingActionButton: offerId != null
          ? FloatingActionButton.extended(
              onPressed: () => _showWriteReviewBottomSheet(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.rate_review, color: Colors.white),
              label: Text(
                'Escribir',
                style: GoogleFonts.hankenGrotesk(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      body: reviewsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(reviewsProvider(targetId)),
        ),
        data: (paginated) {
          final reviews = paginated.items;

          final empty = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_outline_rounded,
                    size: 64, color: AppColors.border),
                const SizedBox(height: 16),
                Text(
                  isOwnProfile
                      ? 'Aún no has recibido reseñas'
                      : 'Aún no hay reseñas',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isOwnProfile
                      ? 'Cuando un cliente te valore, aparecerá aquí.'
                      : 'Este proveedor aún no tiene calificaciones.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );

          return PagedListBody(
            state: paginated,
            empty: empty,
            onLoadMore: () => ref
                .read(paginatedReviewsProvider(targetId).notifier)
                .loadMore(),
            onRefresh: () => ref.refresh(reviewsProvider(targetId).future),
            padding: EdgeInsets.fromLTRB(
                24, 16, 24, 16 + MediaQuery.paddingOf(context).bottom),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              return StaggeredEntrance(
                key: ValueKey('review-${reviews[index].id}'),
                index: index,
                child: ReviewCard(review: reviews[index]),
              );
            },
          );
        },
      ),
    );
  }
}
