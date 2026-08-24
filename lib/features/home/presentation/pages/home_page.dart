import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../providers/home_providers.dart';
import '../../../ads/presentation/providers/ads_provider.dart';
import '../widgets/navigation/bottom_nav_bar.dart';
import '../widgets/navigation/category_grid.dart';
import '../widgets/promo_carousel.dart';
import '../../../auth/presentation/pages/profile_tab.dart';
import '../widgets/unapproved_overlay.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/pages/conversations_inbox_page.dart';
import '../../../chat/presentation/pages/mis_compras_page.dart';
import '../../../chat/presentation/pages/store_sales_page.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../../shared/widgets/skeleton_loader.dart';

// Componentes del Home (hub de navegación)
import '../widgets/header/home_header_expanded.dart';
import '../widgets/home_section_surface.dart';
import '../widgets/sections/top_providers_section.dart';
import '../widgets/store_dashboard/store_dashboard_view.dart';
import '../widgets/provider_dashboard/provider_dashboard_view.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/providers/current_user_provider.dart';

/// Ritmo vertical entre secciones del home.
const double _kSectionGap = 24;

/// Home reestructurado: ya NO filtra contenido.
/// Actúa como hub de navegación (estilo Mercado Libre / Pedidos Ya):
/// - Header expandido con color sólido
/// - Publicidad destacada antes de los accesos principales
/// - Tarjetas de categorías que REDIRIGEN a sus flujos
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(homeTabProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isStore = ref.watch(currentRoleProvider).isStore;

    return Scaffold(
      key: const Key('home-scaffold'),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
              child: _buildSelectedTab(
                context,
                activeTab: activeTab,
                isStore: isStore,
              ),
            ),
          ),
          if (user != null && !user.approved)
            const Positioned.fill(
              child: UnapprovedOverlay(),
            ),
          // La navegación vive como una capa flotante: no reserva una franja
          // rectangular y deja que la pantalla continúe visible alrededor y
          // detrás de la cápsula.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTab(
    BuildContext context, {
    required MainNavigationTab activeTab,
    required bool isStore,
  }) {
    if (activeTab == MainNavigationTab.home) {
      return _buildHomeHub();
    }

    final Widget page = switch (activeTab) {
      MainNavigationTab.home => _buildHomeHub(),
      MainNavigationTab.chats => const ConversationsInboxPage(),
      MainNavigationTab.commerce =>
        isStore ? const StoreSalesPage() : const ConsumerPurchasesPage(),
      MainNavigationTab.profile => const ProfileTab(),
    };

    return KeyedSubtree(
      key: ValueKey<MainNavigationTab>(activeTab),
      child: page,
    );
  }

  /// Hub de navegación: header con publicidad → categorías → destacados.
  /// Sin búsqueda ni filtros: esos viven en las pantallas de listado.
  Widget _buildHomeHub() {
    final selectedType = ref.watch(selectedServiceTypeProvider);
    final isDashboardSelected = selectedType == ServiceType.storeDashboard;
    final currentRole = ref.watch(currentRoleProvider);
    final isConsumer = currentRole.isConsumer;
    final nearbyLabel = currentRole.usesSavedLocationForSearch
        ? 'cerca de tu negocio'
        : 'cerca de ti';
    final allowedTypes = currentRole.allowedServiceTypes;
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);
    final hasUnreadNotifications = (unreadNotifications.valueOrNull ?? 0) > 0;
    Widget? promoSection;
    if (isConsumer) {
      final promosAsync = ref.watch(adsAsPromosProvider(selectedType));
      final hasPromoSlot = promosAsync.isLoading ||
          promosAsync.hasError ||
          (promosAsync.valueOrNull?.isNotEmpty ?? false);
      if (hasPromoSlot) {
        promoSection = Padding(
          key: const Key('home-promo-section'),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey<bool>(promosAsync.isLoading),
              child: promosAsync.when(
                data: (promos) => PromoCarousel(promos: promos),
                loading: () => const PromoSkeleton(),
                error: (error, stack) => _PromoErrorCard(
                  onRetry: () {
                    ref
                        .refresh(adsAsPromosProvider(selectedType).future)
                        .ignore();
                  },
                ),
              ),
            ),
          ),
        );
      }
    }

    return ListView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: bottomNavContentInset(context) + AppSpacing.lg,
      ),
      children: [
        // ── Header expandido: color sólido hasta la barra de estado
        //    y recorte inferior redondeado ──────────────────────────────
        HomeHeaderExpanded(
          hasUnreadNotifications: hasUnreadNotifications,
          onNotificationsTap: () => context.push(RouteNames.notifications),
        ),

        // ── La publicidad abre el contenido principal ───────────────────────
        if (promoSection != null) ...[
          const SizedBox(height: _kSectionGap),
          promoSection,
        ],

        // ── Accesos principales, inmediatamente debajo del banner ───────────
        Padding(
          key: const Key('home-category-section'),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            promoSection == null ? _kSectionGap : AppSpacing.xl,
            AppSpacing.xl,
            isConsumer ? 0 : AppSpacing.lg,
          ),
          child: const CategoryGrid(),
        ),

        if (isDashboardSelected && currentRole.isStore)
          // Dashboard para usuarios tipo tienda
          const StoreDashboardView()
        else if (isDashboardSelected &&
            (currentRole.isMechanic || currentRole.isWorkshop))
          // Dashboard operativo compartido por mecánicos y talleres.
          const ProviderDashboardView()
        else if (isConsumer) ...[
          if (allowedTypes.contains(ServiceType.workshops)) ...[
            const SizedBox(height: _kSectionGap),
            const HomeSectionSurface(
              key: Key('home-provider-section-workshops'),
              child: TopProvidersSection(
                serviceType: ServiceType.workshops,
                title: 'Talleres mejor valorados',
                routePath: RouteNames.workshops,
              ),
            ),
          ],
          if (allowedTypes.contains(ServiceType.mechanic)) ...[
            const SizedBox(height: _kSectionGap),
            const HomeSectionSurface(
              key: Key('home-provider-section-mechanics'),
              child: TopProvidersSection(
                serviceType: ServiceType.mechanic,
                title: 'Mecánicos mejor valorados',
                routePath: RouteNames.mechanics,
              ),
            ),
          ],
        ] else ...[
          // ── Top mecánicos cercanos ────────────────────────────────
          if (allowedTypes.contains(ServiceType.mechanic)) ...[
            const SizedBox(height: _kSectionGap),
            HomeSectionSurface(
              key: const Key('home-provider-section-mechanics'),
              child: TopProvidersSection(
                serviceType: ServiceType.mechanic,
                title: 'Mecánicos $nearbyLabel',
                routePath: RouteNames.mechanics,
              ),
            ),
          ],

          // ── Top talleres cercanos ─────────────────────────────────
          if (allowedTypes.contains(ServiceType.workshops)) ...[
            const SizedBox(height: _kSectionGap),
            HomeSectionSurface(
              key: const Key('home-provider-section-workshops'),
              child: TopProvidersSection(
                serviceType: ServiceType.workshops,
                title: 'Talleres $nearbyLabel',
                routePath: RouteNames.workshops,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _PromoErrorCard extends StatelessWidget {
  const _PromoErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Material(
        key: const Key('promo-error-card'),
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Center(
                  child: AppLineIcon(
                    AppIcons.connectivityError,
                    color: AppColors.errorInk,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No pudimos cargar la publicidad',
                      style: AppTypography.title,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Comprueba tu conexión e inténtalo de nuevo.',
                      style: AppTypography.meta,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryInk,
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                      ),
                      child: Text('Reintentar', style: AppTypography.label),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
