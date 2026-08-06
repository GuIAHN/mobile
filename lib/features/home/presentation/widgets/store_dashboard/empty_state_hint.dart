import 'package:flutter/material.dart';
import 'app_tokens.dart';

class EmptyStateHint extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const EmptyStateHint({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTokens.accentSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppTokens.accentDark,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onAction,
            child: Text(
              '$actionLabel →',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTokens.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
