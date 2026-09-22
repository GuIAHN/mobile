import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/notifications/notification_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';

/// Notificación interna compacta alineada con el sistema visual de GuIA.
///
/// Usa una superficie blanca estable, un único acento semántico y movimiento
/// breve. No incluye progreso ni efectos de vidrio para no competir con el
/// contenido principal de la pantalla.
class AppNotificationToast extends StatefulWidget {
  const AppNotificationToast({
    super.key,
    required this.notification,
    required this.onDismissed,
    this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onDismissed;
  final VoidCallback? onTap;

  @override
  State<AppNotificationToast> createState() => _AppNotificationToastState();
}

class _AppNotificationToastState extends State<AppNotificationToast>
    with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _exitController;
  late final Animation<double> _enterOpacity;
  late final Animation<Offset> _enterOffset;
  late final Animation<double> _exitOpacity;

  Timer? _autoDismissTimer;
  bool _started = false;
  bool _isExiting = false;
  bool _dismissed = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _enterOpacity = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutCubic,
    );
    _enterOffset = Tween<Offset>(
      begin: const Offset(0, -0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic),
    );
    _exitOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _notifyDismissed();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _enterController.value = 1;
    } else {
      _enterController.forward();
    }
    _autoDismissTimer = Timer(widget.notification.duration, _triggerExit);
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _enterController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _triggerExit() {
    if (_isExiting || !mounted) return;
    _isExiting = true;
    _autoDismissTimer?.cancel();
    if (_reduceMotion) {
      _notifyDismissed();
    } else {
      _exitController.forward();
    }
  }

  void _notifyDismissed() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final type = notification.type;
    final title = notification.title?.trim().isNotEmpty == true
        ? notification.title!.trim()
        : type.label;
    final semanticLabel = '${type.label}. $title. ${notification.message}';

    void handleTap() {
      final onTap = widget.onTap;
      if (onTap == null) return;
      onTap();
      _triggerExit();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_enterController, _exitController]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _isExiting ? _exitOpacity : _enterOpacity,
          child: SlideTransition(
            position: _isExiting
                ? const AlwaysStoppedAnimation(Offset.zero)
                : _enterOffset,
            child: child,
          ),
        );
      },
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: Material(
          color: Colors.transparent,
          child: Container(
            key: const Key('app-notification-toast-card'),
            constraints: const BoxConstraints(minHeight: 76),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: widget.onTap == null ? null : handleTap,
                      excludeFromSemantics: true,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          14,
                          12,
                          notification.isDismissible ? 4 : 14,
                          12,
                        ),
                        child: Semantics(
                          container: true,
                          liveRegion: true,
                          button: widget.onTap != null,
                          onTap: widget.onTap == null ? null : handleTap,
                          label: widget.onTap == null
                              ? semanticLabel
                              : '$semanticLabel. Abrir',
                          excludeSemantics: true,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 32,
                                child: AppLineIcon(
                                  type.icon,
                                  color: type.accentColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      notification.message,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                        height: 1.35,
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
                  ),
                  if (notification.isDismissible)
                    Semantics(
                      container: true,
                      button: true,
                      label: 'Cerrar notificación',
                      onTap: _triggerExit,
                      excludeSemantics: true,
                      child: IconButton(
                        key: const Key('app-notification-close'),
                        onPressed: _triggerExit,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        icon: const AppLineIcon(
                          AppIcons.close,
                          size: AppIconSize.action,
                          color: AppColors.textMeta,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
