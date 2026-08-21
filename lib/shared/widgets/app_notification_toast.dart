import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/notifications/notification_model.dart';
import '../../core/theme/app_colors.dart';

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
  });

  final NotificationModel notification;
  final VoidCallback onDismissed;

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
        liveRegion: true,
        label: semanticLabel,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: Container(
            key: const Key('app-notification-toast-card'),
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: type.backgroundColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(type.icon, color: type.accentColor, size: 22),
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
                if (notification.isDismissible)
                  IconButton(
                    key: const Key('app-notification-close'),
                    onPressed: _triggerExit,
                    tooltip: 'Cerrar notificación',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 19,
                      color: AppColors.textMeta,
                    ),
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
