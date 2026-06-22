import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/app_notification_host.dart';
import 'shared/widgets/maintenance_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/providers/auth_state.dart';

class GuiAutomotrizApp extends ConsumerWidget {
  const GuiAutomotrizApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

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
            message: authState.errorMessage ?? 'El sistema está en mantenimiento.',
          );
        }
        return AppNotificationHost(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

