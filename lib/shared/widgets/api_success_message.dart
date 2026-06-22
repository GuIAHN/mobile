import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class ApiSuccessMessage extends StatelessWidget {
  final String? message;
  final VoidCallback? onClose;

  const ApiSuccessMessage({
    super.key,
    required this.message,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                message!,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                  height: 1.3,
                ),
              ),
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClose,
              child: const Icon(Icons.close, color: AppColors.success, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
