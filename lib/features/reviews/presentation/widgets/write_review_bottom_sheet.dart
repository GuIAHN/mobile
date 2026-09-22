import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/my_review_status.dart';
import '../providers/reviews_providers.dart';
import 'star_rating_input.dart';

class WriteReviewBottomSheet extends ConsumerStatefulWidget {
  final String? targetId;
  final String? conversationId;
  final String providerName;
  final MyReviewStatus? initialStatus;
  final bool readOnly;

  const WriteReviewBottomSheet({
    super.key,
    this.targetId,
    this.conversationId,
    this.providerName = 'este proveedor',
    this.initialStatus,
    this.readOnly = false,
  })  : assert(
          targetId != null || conversationId != null,
          'A review needs a targetId or conversationId',
        ),
        assert(
          initialStatus != null || targetId != null,
          'An initialStatus is required when reviewing by conversationId only',
        );

  @override
  ConsumerState<WriteReviewBottomSheet> createState() =>
      _WriteReviewBottomSheetState();
}

class _WriteReviewBottomSheetState
    extends ConsumerState<WriteReviewBottomSheet> {
  int _rating = 0;
  bool _initialized = false;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _initialize(MyReviewStatus status) {
    if (_initialized) return;
    _initialized = true;
    _rating = status.review?.rating ?? 0;
    _commentController.text = status.review?.comentario ?? '';
  }

  Future<void> _submitReview(MyReviewStatus status) async {
    if (_rating == 0) return;
    final comment = _commentController.text.trim();
    final notifier = ref.read(createReviewProvider.notifier);
    final success = status.review != null
        ? await notifier.updateReview(
            reviewId: status.review!.id,
            rating: _rating,
            comentario: comment,
          )
        : await notifier.createReview(
            conversationId: widget.conversationId,
            targetId: widget.conversationId == null ? widget.targetId : null,
            rating: _rating,
            comentario: comment,
          );

    if (success && mounted) {
      final targetId = widget.targetId;
      if (targetId != null && targetId.isNotEmpty) {
        ref.invalidate(reviewsProvider(targetId));
        ref.invalidate(myReviewProvider(targetId));
      }
      // This sheet is shared by pending reviews, chat and provider profiles.
      // Invalidate once here so every successful entry point refreshes the
      // badge/gate without requiring caller-specific duplicate requests.
      ref.invalidate(pendingReviewsProvider);
      final conversationId = widget.conversationId;
      if (conversationId != null && conversationId.isNotEmpty) {
        await markStoreReviewHandled(ref, conversationId);
      }
      if (!mounted) return;
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = widget.initialStatus == null
        ? ref.watch(myReviewProvider(widget.targetId!))
        : AsyncValue.data(widget.initialStatus!);
    final submitState = ref.watch(createReviewProvider);

    return Container(
      key: const Key('write-review-sheet-surface'),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom +
            AppSpacing.xl2,
        top: AppSpacing.md,
        left: AppSpacing.xl2,
        right: AppSpacing.xl2,
      ),
      child: statusAsync.when(
        loading: () => const SizedBox(
          height: 300,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (error, _) => SizedBox(
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLineIcon(
                AppIcons.cloudError,
                size: AppIconSize.feature,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('No pudimos cargar tu valoración',
                  style: AppTypography.title, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () =>
                    ref.invalidate(myReviewProvider(widget.targetId!)),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
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
        data: (status) {
          _initialize(status);
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl2),
                Text(
                  status.hasReviewed
                      ? widget.readOnly
                          ? 'Tu reseña'
                          : 'Editar valoración'
                      : '¿Cómo fue tu experiencia?',
                  style: AppTypography.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.readOnly
                      ? 'Esta fue tu valoración para ${widget.providerName}.'
                      : 'Califica a ${widget.providerName}. Las estrellas son obligatorias.',
                  style: AppTypography.bodySm,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl3),
                Center(
                  child: StarRatingInput(
                    rating: _rating,
                    onChanged: widget.readOnly
                        ? null
                        : (value) => setState(() => _rating = value),
                    size: 36,
                    readOnly: widget.readOnly,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _rating == 0
                      ? widget.readOnly
                          ? 'Sin puntuación'
                          : 'Selecciona de 1 a 5 estrellas'
                      : '$_rating de 5 estrellas',
                  style: AppTypography.meta.copyWith(
                    color: _rating == 0
                        ? AppColors.errorInk
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.readOnly) ...[
                  const SizedBox(height: AppSpacing.xl3),
                  Text('TU COMENTARIO', style: AppTypography.overline),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _commentController.text.trim().isEmpty
                        ? 'No agregaste un comentario.'
                        : _commentController.text.trim(),
                    key: const Key('review-read-only-comment'),
                    style: AppTypography.body,
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.xl3),
                  Text('COMENTARIO (OPCIONAL)', style: AppTypography.overline),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _commentController,
                    maxLines: 4,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Cuéntanos sobre tu experiencia...',
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.all(AppSpacing.lg),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide:
                            const BorderSide(color: AppColors.borderFocus),
                      ),
                    ),
                    style: AppTypography.body,
                  ),
                  if (submitState.hasError) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      submitState.error.toString(),
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.errorInk),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: AppSpacing.buttonHeightLg,
                    child: ElevatedButton(
                      onPressed: _rating > 0 && !submitState.isLoading
                          ? () => _submitReview(status)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        disabledBackgroundColor: AppColors.disabledBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        elevation: 0,
                      ),
                      child: submitState.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              status.hasReviewed
                                  ? 'GUARDAR CAMBIOS'
                                  : 'PUBLICAR RESEÑA',
                              style: AppTypography.label.copyWith(
                                color: _rating > 0
                                    ? Colors.white
                                    : AppColors.disabledText,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
