import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/user_notification.dart';
import 'notification_time_formatter.dart';
import 'notification_visual_style.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.isMarking,
    required this.onTap,
  });

  final UserNotification notification;
  final bool isMarking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = NotificationVisualStyle.forType(notification.type);

    return Semantics(
      button: true,
      enabled: !isMarking,
      excludeSemantics: true,
      label: 'Abrir y marcar como leída: ${notification.title}',
      child: Container(
        key: Key('notification-card-${notification.id}'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppDecorations.soft,
        ),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isMarking ? null : onTap,
            child: Stack(
              children: [
                const Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: ColoredBox(color: AppColors.primary),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: visual.background,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: isMarking
                            ? SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: visual.foreground,
                                ),
                              )
                            : Icon(
                                visual.icon,
                                color: visual.foreground,
                                size: AppSpacing.iconMd,
                              ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: AppTypography.title,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              notification.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Pendiente · ${NotificationTimeFormatter.relative(notification.createdAt.toLocal())}',
                              style: AppTypography.meta.copyWith(
                                color: AppColors.textMeta,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
