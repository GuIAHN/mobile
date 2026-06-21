import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/notifications/notification_model.dart';
import '../../core/notifications/notification_type.dart';

/// Toast visual premium de una notificación del sistema AppNotification.
///
/// Implementa:
/// - Animación de **entrada**: slide-up (30px) + fade, 320ms, easeOutCubic
/// - Animación de **salida**: fade-out + scale-down (0.95×), 200ms, easeIn
/// - **Progress bar** inferior que drena durante [NotificationModel.duration]
/// - **Micro-pulso** del icono al montar (scale 1.0 → 1.25 → 1.0, 400ms)
/// - Glassmorphism: BackdropFilter + color semántico 92% opacidad
/// - Franja lateral izquierda del color de acento
class AppNotificationToast extends StatefulWidget {
  final NotificationModel notification;

  /// Callback invocado cuando la animación de salida ha terminado.
  final VoidCallback onDismissed;

  const AppNotificationToast({
    super.key,
    required this.notification,
    required this.onDismissed,
  });

  @override
  State<AppNotificationToast> createState() => _AppNotificationToastState();
}

class _AppNotificationToastState extends State<AppNotificationToast>
    with TickerProviderStateMixin {
  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _enterController;
  late final AnimationController _exitController;
  late final AnimationController _progressController;
  late final AnimationController _iconPulseController;

  // ── Animations ─────────────────────────────────────────────────────────────
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _fadeOut;
  late final Animation<double> _scaleOut;
  late final Animation<double> _iconPulse;

  Timer? _autoDismissTimer;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    // ── Entrada ───────────────────────────────────────────────────────────────
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeIn = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutCubic,
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutCubic,
    ));

    // ── Salida ────────────────────────────────────────────────────────────────
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _scaleOut = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismissed();
      }
    });

    // ── Progress bar ──────────────────────────────────────────────────────────
    _progressController = AnimationController(
      vsync: this,
      duration: widget.notification.duration,
      value: 1.0,
    );

    // ── Icono micro-pulso ─────────────────────────────────────────────────────
    _iconPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _iconPulse = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _iconPulseController,
      curve: Curves.easeInOut,
    ));

    // ── Arranque ──────────────────────────────────────────────────────────────
    _enterController.forward().then((_) {
      _iconPulseController.forward();
      _progressController.reverse();
      _autoDismissTimer = Timer(widget.notification.duration, _triggerExit);
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _enterController.dispose();
    _exitController.dispose();
    _progressController.dispose();
    _iconPulseController.dispose();
    super.dispose();
  }

  void _triggerExit() {
    if (_isExiting || !mounted) return;
    _isExiting = true;
    _autoDismissTimer?.cancel();
    _exitController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final type = n.type;

    return AnimatedBuilder(
      animation: Listenable.merge([_enterController, _exitController]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _isExiting ? _fadeOut : _fadeIn,
          child: ScaleTransition(
            scale: _isExiting
                ? _scaleOut
                : const AlwaysStoppedAnimation(1.0),
            child: SlideTransition(
              position: _isExiting
                  ? const AlwaysStoppedAnimation(Offset.zero)
                  : _slideUp,
              child: child,
            ),
          ),
        );
      },
      child: _buildBody(type, n),
    );
  }

  Widget _buildBody(NotificationType type, NotificationModel n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: type.backgroundColor.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: type.accentColor.withValues(alpha: 0.25),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: type.accentColor.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Franja lateral ──────────────────────────────────────────
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: type.accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                ),

                // ── Contenido ────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icono con micro-pulso
                            AnimatedBuilder(
                              animation: _iconPulse,
                              builder: (context, child) => Transform.scale(
                                scale: _iconPulse.value,
                                child: child,
                              ),
                              child: Icon(
                                type.icon,
                                color: type.accentColor,
                                size: 22,
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Texto
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (n.title != null) ...[
                                    Text(
                                      n.title!,
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: type.accentColor,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    n.message,
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: type.accentColor
                                          .withValues(alpha: 0.85),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Botón de cierre
                            if (n.isDismissible) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _triggerExit,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: type.accentColor
                                        .withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color:
                                        type.accentColor.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ── Progress bar ────────────────────────────────────────
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, _) {
                          return Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: _progressController.value,
                                backgroundColor:
                                    type.accentColor.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  type.accentColor.withValues(alpha: 0.6),
                                ),
                                minHeight: 3,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 10),
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
