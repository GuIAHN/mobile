import 'package:flutter/material.dart';

import '../../domain/entities/my_review_status.dart';
import '../widgets/write_review_bottom_sheet.dart';

class ReviewEditorSheet extends StatelessWidget {
  const ReviewEditorSheet({
    super.key,
    this.targetId,
    this.conversationId,
    required this.providerName,
    this.readOnly = false,
  });

  final String? targetId;
  final String? conversationId;
  final String providerName;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: WriteReviewBottomSheet(
        targetId: targetId,
        conversationId: conversationId,
        providerName: providerName,
        initialStatus: targetId == null && !readOnly
            ? const MyReviewStatus(hasReviewed: false)
            : null,
        readOnly: readOnly,
      ),
    );
  }
}
