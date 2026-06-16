import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage/secure_storage.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_type_page.dart';
import '../../features/auth/presentation/pages/register_user_page.dart';
import '../../features/auth/presentation/pages/register_workshop_page.dart';
import '../../features/auth/presentation/pages/register_mechanic_page.dart';
import '../../features/auth/presentation/pages/register_store_page.dart';
import '../../features/vehicles/presentation/pages/register_vehicles_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import 'route_names.dart';

/// Proveedor global del router de la app.
/// Reactive: se reconstruye si el estado de autenticación cambia.
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter(ref).router;
});

class AppRouter {
  final Ref _ref;

  AppRouter(this._ref);

  GoRouter get router => GoRouter(
        initialLocation: RouteNames.splash,
        debugLogDiagnostics: true,
        redirect: _redirect,
        routes: [
          // ── Splash / Auth guard ─────────────────────────────────────────
          GoRoute(
            path: RouteNames.splash,
            builder: (context, state) => const _SplashPage(),
          ),

          // ── Onboarding ────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.onboarding,
            name: 'onboarding',
            builder: (context, state) => const OnboardingPage(),
          ),

          // ── Auth ─────────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.login,
            name: 'login',
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: RouteNames.register,
            name: 'register',
            builder: (context, state) => const RegisterTypePage(),
            routes: [
              GoRoute(
                path: 'user',
                name: 'registerUser',
                builder: (context, state) => const RegisterUserPage(),
              ),
              GoRoute(
                path: 'workshop',
                name: 'registerWorkshop',
                builder: (context, state) => const RegisterWorkshopPage(),
              ),
              GoRoute(
                path: 'mechanic',
                name: 'registerMechanic',
                builder: (context, state) => const RegisterMechanicPage(),
              ),
              GoRoute(
                path: 'store',
                name: 'registerStore',
                builder: (context, state) => const RegisterStorePage(),
              ),
              GoRoute(
                path: 'vehicles',
                name: 'registerVehicles',
                builder: (context, state) => const RegisterVehiclesPage(),
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.forgotPassword,
            name: 'forgotPassword',
            builder: (context, state) =>
                const _PlaceholderPage(title: 'Recuperar contraseña'),
          ),

          // ── Home ─────────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.home,
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),

          // ── Vehículos ────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.vehicles,
            name: 'vehicles',
            builder: (context, state) =>
                const _PlaceholderPage(title: 'Vehículos'),
            routes: [
              GoRoute(
                path: ':id',
                name: 'vehicleDetail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _PlaceholderPage(title: 'Vehículo $id');
                },
              ),
            ],
          ),
        ],
      );

  /// Guard global: redirige según estado de auth y onboarding.
  Future<String?> _redirect(BuildContext context, GoRouterState state) async {
    final storage = _ref.read(secureStorageProvider);
    final hasToken = await storage.hasToken();

    final isAuthRoute = state.matchedLocation == RouteNames.login ||
        state.matchedLocation == RouteNames.register ||
        state.matchedLocation == RouteNames.registerUser ||
        state.matchedLocation == RouteNames.registerWorkshop ||
        state.matchedLocation == RouteNames.registerMechanic ||
        state.matchedLocation == RouteNames.registerStore ||
        state.matchedLocation == RouteNames.registerVehicles ||
        state.matchedLocation == RouteNames.forgotPassword ||
        state.matchedLocation == RouteNames.splash ||
        state.matchedLocation == RouteNames.onboarding;

    // Si no tiene token y no está en ruta de auth → redirigir
    if (!hasToken && !isAuthRoute) {
      return RouteNames.login;
    }

    // Si tiene token y está en splash → home
    if (hasToken && state.matchedLocation == RouteNames.splash) {
      return RouteNames.home;
    }

    // Si no tiene token y está en splash → onboarding o login
    if (!hasToken && state.matchedLocation == RouteNames.splash) {
      return RouteNames.onboarding; // Forzar onboarding para visualización
    }

    return null;
  }
}

// ── Páginas temporales (reemplazar por las de cada feature) ──────────────────

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Página placeholder usada hasta que se implementen las features reales.
class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
