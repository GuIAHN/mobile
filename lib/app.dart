import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/app_notification_host.dart';
import 'shared/widgets/maintenance_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/providers/auth_state.dart';
import 'core/services/socket_service.dart';
import 'core/session/session_state_coordinator.dart';
import 'core/notifications/foreground_notification_toast_provider.dart';
import 'core/notifications/notification_model.dart';
import 'features/notifications/presentation/providers/notifications_providers.dart';
import 'features/notifications/services/notification_route_resolver.dart';
import 'features/notifications/services/push_notifications_service.dart';

class GuiAutomotrizApp extends ConsumerStatefulWidget {
  const GuiAutomotrizApp({super.key});

  @override
  ConsumerState<GuiAutomotrizApp> createState() => _GuiAutomotrizAppState();
}

class _GuiAutomotrizAppState extends ConsumerState<GuiAutomotrizApp>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _authenticationRecoverySub;
  StreamSubscription<NotificationTap>? _notificationTapSub;
  bool _recoveringRealtime = false;
  NotificationTap? _pendingNotificationTap;
  String? _lastNotificationTapKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authenticationRecoverySub = ref
        .read(socketServiceProvider)
        .onAuthenticationRequired
        .listen((_) => unawaited(_recoverRealtimeSession(verifySession: true)));
    _notificationTapSub = PushNotificationsService.onNotificationTap
        .listen(_queueNotificationTap);
    final initialTap = PushNotificationsService.takeInitialNotificationTap();
    if (initialTap != null) _pendingNotificationTap = initialTap;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flushPendingNotificationTap();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_recoverRealtimeSession());
    }
  }

  Future<void> _recoverRealtimeSession({bool verifySession = false}) async {
    if (_recoveringRealtime ||
        ref.read(authProvider).status != AuthStatus.authenticated) {
      return;
    }

    _recoveringRealtime = true;
    try {
      // A server-requested authentication recovery verifies the session and
      // lets AuthInterceptor rotate an expired JWT. A normal app resume only
      // asks the socket to reconnect when needed; it must not refetch the full
      // profile or tear down a healthy transport on every foreground event.
      if (verifySession) {
        await ref.read(authProvider.notifier).refreshUser();
        if (!mounted ||
            ref.read(authProvider).status != AuthStatus.authenticated) {
          return;
        }
      }
      await ref.read(socketServiceProvider).connect();
    } catch (error) {
      debugPrint('[Realtime] No se pudo recuperar la conexión: $error');
    } finally {
      _recoveringRealtime = false;
    }
  }

  void _queueNotificationTap(NotificationTap tap) {
    _pendingNotificationTap = tap;
    _flushPendingNotificationTap();
  }

  void _flushPendingNotificationTap() {
    if (!mounted ||
        ref.read(authProvider).status != AuthStatus.authenticated ||
        _pendingNotificationTap == null) {
      return;
    }

    final tap = _pendingNotificationTap!;
    final destination = NotificationRouteResolver.resolve(
      type: tap.type,
      data: tap.data,
    );
    _pendingNotificationTap = null;
    final dedupeId = tap.notificationId ??
        tap.data['messageId']?.toString() ??
        tap.data['message_id']?.toString();
    if (dedupeId != null) {
      final tapKey = '$dedupeId|$destination';
      if (_lastNotificationTapKey == tapKey) return;
      _lastNotificationTapKey = tapKey;
    }

    if (tap.notificationId != null) {
      unawaited(_markNotificationRead(tap.notificationId!));
    }
    _pushNotificationDestination(destination);
  }

  void _openInAppNotification(NotificationModel notification) {
    final destination = notification.destinationPath;
    if (destination == null) return;
    if (notification.sourceId != null) {
      unawaited(_markNotificationRead(notification.sourceId!));
    }
    _pushNotificationDestination(destination);
  }

  void _pushNotificationDestination(String destination) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = ref.read(appRouterProvider);
      final current = router.routerDelegate.currentConfiguration.uri.toString();
      if (current == destination) return;
      unawaited(router.push<void>(destination));
    });
  }

  Future<void> _markNotificationRead(String notificationId) async {
    final result = await ref.read(markNotificationReadUseCaseProvider)(
      notificationId,
    );
    result.fold(
      (_) {},
      (_) => ref.invalidate(unreadNotificationsCountProvider),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authenticationRecoverySub?.cancel();
    _notificationTapSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ Línea temporal para forzar reset al Onboarding. Coméntala tras reiniciar.

    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Mantiene viva la escucha de notificaciones en tiempo real (toast
    // interno cuando la app está en foreground)
    ref.watch(foregroundNotificationToastProvider);

    ref.listen<AuthStatus>(
      authProvider.select((s) => s.status),
      (previous, next) {
        if (next == AuthStatus.authenticated) {
          _flushPendingNotificationTap();
        } else if (next == AuthStatus.unauthenticated) {
          _discardPendingNotificationNavigation();
        }
      },
    );

    ref.listen<String?>(
      authProvider.select((state) => state.user?.id),
      (previous, next) {
        if (previous == next) return;
        // Conservar el tap que abrió la app mientras se hidrata por primera
        // vez la misma sesión. Un logout (A -> null) o un cambio directo
        // (A -> B) sí debe descartar cualquier destino privado anterior.
        if (previous != null || next == null) {
          _discardPendingNotificationNavigation();
        }
      },
    );

    // Mantiene activa la frontera que reinicia cachés y transportes cuando
    // cambia la identidad dentro del mismo ProviderScope.
    ref.watch(sessionStateCoordinatorProvider);

    return MaterialApp.router(
      title: 'guIAutomotriz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final authState = ref.watch(authProvider);
        if (authState.status == AuthStatus.error && authState.user == null) {
          return MaintenancePage(
            message:
                authState.errorMessage ?? 'El sistema está en mantenimiento.',
          );
        }
        return AppNotificationHost(
          onNotificationTap: _openInAppNotification,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  void _discardPendingNotificationNavigation() {
    _pendingNotificationTap = null;
    _lastNotificationTapKey = null;
    PushNotificationsService.discardPendingNotificationTap();
  }
}
