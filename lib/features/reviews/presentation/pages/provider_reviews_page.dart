import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/reviews_providers.dart';
import '../widgets/review_card.dart';
import '../widgets/write_review_bottom_sheet.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/staggered_entrance.dart';

class ProviderReviewsPage extends ConsumerWidget {
  final String targetId;
  final String? conversationId;

  const ProviderReviewsPage({
    super.key,
    required this.targetId,
    this.conversationId,
  });

  void _showWriteReviewBottomSheet(BuildContext context) {
    if (conversationId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WriteReviewBottomSheet(
        targetId: targetId,
        conversationId: conversationId!,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsProvider(targetId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Reseñas',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      floatingActionButton: conversationId != null
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

          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_outline_rounded, size: 64, color: AppColors.border),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no hay reseñas',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Este proveedor aún no tiene calificaciones.',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(reviewsProvider(targetId)),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                return StaggeredEntrance(
                  index: index,
                  child: ReviewCard(review: reviews[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
