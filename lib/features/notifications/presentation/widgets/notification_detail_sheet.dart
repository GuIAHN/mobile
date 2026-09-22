import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/user_notification.dart';
import 'notification_time_formatter.dart';
import 'notification_visual_style.dart';

Future<void> showNotificationDetailSheet(
  BuildContext context, {
  required UserNotification notification,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    builder: (_) => NotificationDetailSheet(notification: notification),
  );
}

class NotificationDetailSheet extends StatelessWidget {
  const NotificationDetailSheet({
    super.key,
    required this.notification,
  });

  final UserNotification notification;

  @override
  Widget build(BuildContext context) {
    final visual = NotificationVisualStyle.forType(notification.type);
    final media = MediaQuery.of(context);

    return Semantics(
      container: true,
      scopesRoute: true,
      explicitChildNodes: true,
      label: 'Detalle de notificación',
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Material(
          color: AppColors.surface,
          borderRadius: AppDecorations.sheet,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl2,
                    AppSpacing.md,
                    AppSpacing.xl2,
                    AppSpacing.xl2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.grey400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: AppIconSize.feature,
                            child: AppLineIcon(
                              visual.icon,
                              color: visual.foreground,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: AppTypography.h2,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${visual.label.toUpperCase()} · ${NotificationTimeFormatter.full(notification.createdAt.toLocal())}',
                                  style: AppTypography.meta.copyWith(
                                    color: AppColors.textMeta,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl3),
                      Text('MENSAJE', style: AppTypography.overline),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        notification.body,
                        style: AppTypography.body.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl2,
                    AppSpacing.sm,
                    AppSpacing.xl2,
                    AppSpacing.sm + media.padding.bottom,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      button: true,
                      excludeSemantics: true,
                      label: 'Cerrar detalle de notificación',
                      child: SizedBox(
                        height: AppSpacing.buttonHeightMd,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cerrar',
                            style: AppTypography.label.copyWith(
                              color: AppColors.primaryInk,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
