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
import 'core/storage/secure_storage.dart';
import 'core/notifications/foreground_notification_toast_provider.dart';

class GuiAutomotrizApp extends ConsumerStatefulWidget {
  const GuiAutomotrizApp({super.key});

  @override
  ConsumerState<GuiAutomotrizApp> createState() => _GuiAutomotrizAppState();
}

class _GuiAutomotrizAppState extends ConsumerState<GuiAutomotrizApp>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _authenticationRecoverySub;
  bool _recoveringRealtime = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authenticationRecoverySub = ref
        .read(socketServiceProvider)
        .onAuthenticationRequired
        .listen((_) => unawaited(_recoverRealtimeSession()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_recoverRealtimeSession(forceReconnect: true));
    }
  }

  Future<void> _recoverRealtimeSession({bool forceReconnect = false}) async {
    if (_recoveringRealtime ||
        ref.read(authProvider).status != AuthStatus.authenticated) {
      return;
    }

    _recoveringRealtime = true;
    try {
      final storage = ref.read(secureStorageProvider);
      final tokenBeforeRefresh = await storage.getToken();
      if (!mounted) return;
      // This lightweight authenticated request rotates an expired JWT via
      // AuthInterceptor before Socket.IO reconnects.
      await ref.read(authProvider.notifier).refreshUser();
      if (!mounted ||
          ref.read(authProvider).status != AuthStatus.authenticated) {
        return;
      }
      final tokenAfterRefresh = await storage.getToken();
      if (!mounted) return;
      // AuthInterceptor already recreates the socket when it rotates the
      // token. Force a fresh transport on resume only when the token did not
      // change, avoiding a duplicate connection attempt.
      final shouldForceReconnect =
          forceReconnect && tokenBeforeRefresh == tokenAfterRefresh;
      await ref.read(socketServiceProvider).connect(
            force: shouldForceReconnect,
          );
    } catch (error) {
      debugPrint('[Realtime] No se pudo recuperar la conexión: $error');
    } finally {
      _recoveringRealtime = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authenticationRecoverySub?.cancel();
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
        final socket = ref.read(socketServiceProvider);
        if (next == AuthStatus.authenticated) {
          socket.connect();
        } else if (next == AuthStatus.unauthenticated) {
          socket.disconnect();
        }
      },
    );

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
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
