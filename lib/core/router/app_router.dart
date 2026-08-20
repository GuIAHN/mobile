import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage/secure_storage.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/register_type_page.dart';
import '../../features/auth/presentation/pages/register_user_page.dart';
import '../../features/auth/presentation/pages/register_workshop_page.dart';
import '../../features/auth/presentation/pages/register_mechanic_page.dart';
import '../../features/auth/presentation/pages/register_store_page.dart';
import '../../features/vehicles/presentation/pages/register_vehicles_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/providers_list_page.dart';
import '../../core/domain/enums/service_type.dart';
import '../../features/home/presentation/pages/mechanic_detail_page.dart';
import '../../features/home/presentation/pages/store_detail_page.dart';
import '../../features/chat/presentation/pages/conversations_inbox_page.dart';
import '../../features/chat/presentation/pages/chat_thread_detail_page.dart';
import '../../features/chat/presentation/pages/chat_conversation_page.dart';
import '../../features/chat/presentation/pages/mis_compras_page.dart';
import '../../features/chat/presentation/pages/store_sales_page.dart';
import '../../features/reviews/presentation/pages/provider_reviews_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import 'route_names.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        notifyListeners();
      },
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Proveedor global del router de la app.
final appRouterProvider = Provider<GoRouter>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final listenable = ref.watch(routerNotifierProvider);
  return AppRouter(storage, listenable).router;
});

class AppRouter {
  final SecureStorage _storage;
  final Listenable _listenable;

  AppRouter(this._storage, this._listenable);

  GoRouter get router => GoRouter(
        initialLocation: RouteNames.splash,
        debugLogDiagnostics: true,
        refreshListenable: _listenable,
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
            builder: (context, state) => const ForgotPasswordPage(),
          ),

          // ── Home ─────────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.home,
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: RouteNames.notifications,
            name: 'notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: RouteNames.workshops,
            name: 'workshops',
            builder: (context, state) =>
                const ProvidersListPage(serviceType: ServiceType.workshops),
          ),
          GoRoute(
            path: RouteNames.mechanics,
            name: 'mechanics',
            builder: (context, state) =>
                const ProvidersListPage(serviceType: ServiceType.mechanic),
          ),
          GoRoute(
            path: RouteNames.mechanicDetail,
            name: 'mechanicDetail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return MechanicDetailPage(mechanicId: id);
            },
          ),
          GoRoute(
            path: RouteNames.storeDetail,
            name: 'storeDetail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final isSpareParts =
                  state.uri.queryParameters['type'] == 'spareParts';
              return StoreDetailPage(
                storeId: id,
                serviceType: isSpareParts
                    ? ServiceType.spareParts
                    : ServiceType.workshops,
              );
            },
          ),
          GoRoute(
            path: RouteNames.providerReviews,
            name: 'providerReviews',
            builder: (context, state) {
              final id = state.pathParameters['targetId']!;
              final conversationId =
                  state.uri.queryParameters['conversationId'];
              return ProviderReviewsPage(
                targetId: id,
                conversationId: conversationId,
              );
            },
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

          // ── Chats ────────────────────────────────────────────────────────
          // Compatibilidad temporal con enlaces antiguos:
          // /chats/:requestId/:conversationId.
          GoRoute(
            path: '/chats/:legacyRequestId/:legacyConversationId',
            builder: (context, state) {
              final conversationId =
                  state.pathParameters['legacyConversationId']!;
              return ChatConversationPage(conversationId: conversationId);
            },
          ),
          GoRoute(
            path: RouteNames.chatInbox,
            name: 'chatInbox',
            builder: (context, state) => const ConversationsInboxPage(),
            routes: [
              GoRoute(
                path: ':conversationId',
                name: 'chatConversation',
                builder: (context, state) {
                  final conversationId =
                      state.pathParameters['conversationId']!;
                  return ChatConversationPage(
                    conversationId: conversationId,
                  );
                },
              ),
            ],
          ),

          // ── Operación comercial ──────────────────────────────────────────
          GoRoute(
            path: RouteNames.purchases,
            name: 'purchases',
            builder: (context, state) => const ConsumerPurchasesPage(),
            routes: [
              GoRoute(
                path: ':requestId',
                name: 'purchaseDetail',
                builder: (context, state) {
                  final requestId = state.pathParameters['requestId']!;
                  return ChatThreadDetailPage(threadId: requestId);
                },
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.sales,
            name: 'sales',
            builder: (context, state) => const StoreSalesPage(),
            routes: [
              GoRoute(
                path: ':requestId',
                name: 'saleDetail',
                builder: (context, state) {
                  final requestId = state.pathParameters['requestId']!;
                  return ChatThreadDetailPage(threadId: requestId);
                },
              ),
            ],
          ),
        ],
      );

  /// Guard global: redirige según estado de auth y onboarding.
  Future<String?> _redirect(BuildContext context, GoRouterState state) async {
    final hasToken = await _storage.hasToken();
    final seenOnboarding = await _storage.hasSeenOnboarding();

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

    // Si no tiene token y no está en una ruta pública/auth → login
    if (!hasToken && !isAuthRoute) {
      return RouteNames.login;
    }

    // Si tiene token e intenta acceder a login, registro u onboarding → home
    if (hasToken && isAuthRoute && state.matchedLocation != RouteNames.splash) {
      return RouteNames.home;
    }

    // Rutas iniciales desde Splash
    if (state.matchedLocation == RouteNames.splash) {
      if (hasToken) {
        return RouteNames.home;
      } else {
        return seenOnboarding ? RouteNames.login : RouteNames.onboarding;
      }
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
