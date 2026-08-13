import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
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
import '../../../chat/presentation/pages/chat_inbox_page.dart';
import '../../../chat/presentation/pages/mis_compras_page.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/section_header.dart';

// Componentes del Home (hub de navegación)
import '../widgets/header/home_header_expanded.dart';
import '../widgets/home_section_surface.dart';
import '../widgets/sections/top_providers_section.dart';
import '../widgets/sections/my_garage_section.dart';
import '../widgets/store_dashboard/store_dashboard_view.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/providers/current_user_provider.dart';

/// Ritmo vertical entre secciones del home.
const double _kSectionGap = 24;

/// Home reestructurado: ya NO filtra contenido.
/// Actúa como hub de navegación (estilo Mercado Libre / Pedidos Ya):
/// - Header expandido con color sólido y publicidad integrada
/// - Tarjetas grandes de categorías que REDIRIGEN a sus flujos
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
      backgroundColor: AppColors.background,
      // El body se extiende por debajo de la barra para que el contenido se vea
      // continuo detrás de la parte saliente del logo central.
      extendBody: true,
      bottomNavigationBar: const BottomNavBar(),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 250),
            child: activeTab == 0
                ? _buildHomeHub()
                : SafeArea(
                    bottom: false,
                    child: Padding(
                      // Las demás vistas no deben quedar tapadas por la barra.
                      padding: EdgeInsets.only(
                        bottom: bottomNavContentInset(context),
                      ),
                      child: activeTab == 1
                          ? const ChatInboxPage()
                          : activeTab == 2 && !isStore
                              ? const MisComprasPage()
                              : const ProfileTab(),
                    ),
                  ),
          ),
          if (user != null && !user.approved)
            const Positioned.fill(
              child: UnapprovedOverlay(),
            ),
        ],
      ),
    );
  }

  /// Hub de navegación: header con publicidad → categorías → destacados.
  /// Sin búsqueda ni filtros: esos viven en las pantallas de listado.
  Widget _buildHomeHub() {
    final selectedType = ref.watch(selectedServiceTypeProvider);
    final isDashboardSelected = selectedType == ServiceType.storeDashboard;
    final currentRole = ref.watch(currentRoleProvider);
    final isConsumer = currentRole.isConsumer;
    final promosAsync = ref.watch(adsAsPromosProvider(selectedType));
    final allowedTypes = currentRole.allowedServiceTypes;
    final hasUnreadChats = ref.watch(hasUnreadChatThreadsProvider);
    // La tienda no tiene garage: aunque isDashboardSelected quede desactualizado
    // (ej. al volver de la lista de mecánicos/talleres), el rol manda.
    final showGarage =
        !isConsumer && !isDashboardSelected && !currentRole.isStore;
    final promoSection = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey<bool>(promosAsync.isLoading),
          child: promosAsync.when(
            data: (promos) => PromoCarousel(promos: promos),
            loading: () => const PromoSkeleton(),
            error: (error, stack) => _PromoErrorCard(
              onRetry: () {
                ref.invalidate(adsAsPromosProvider(selectedType));
              },
            ),
          ),
        ),
      ),
    );

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
          hasUnreadNotifications: hasUnreadChats,
          onNotificationsTap: () =>
              ref.read(homeTabProvider.notifier).state = 1,
        ),

        if (showGarage) ...[
          // ── Mi garage: vehículos del usuario con acceso rápido ─────────
          const SizedBox(height: _kSectionGap),
          const MyGarageSection(),

          // ── Publicidad ──────────────────────────────────────────────
          const SizedBox(height: _kSectionGap),
          promoSection,
        ],

        if (isConsumer) ...[
          const SizedBox(height: _kSectionGap),
          const SectionHeader(
            title: '¿Qué necesitas buscar hoy?',
            icon: Icons.search_rounded,
          ),
        ],

        // ── Tarjetas de acción principales ──────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            isConsumer ? 12 : _kSectionGap,
            20,
            16,
          ),
          child: const CategoryGrid(),
        ),

        if (isConsumer) promoSection,

        if (isDashboardSelected && currentRole.isStore)
          // Dashboard para usuarios tipo tienda
          const StoreDashboardView()
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
            const TopProvidersSection(
              serviceType: ServiceType.mechanic,
              title: 'Mecánicos cerca de ti',
              routePath: RouteNames.mechanics,
            ),
          ],

          // ── Top talleres cercanos ─────────────────────────────────
          if (allowedTypes.contains(ServiceType.workshops)) ...[
            const SizedBox(height: _kSectionGap),
            const TopProvidersSection(
              serviceType: ServiceType.workshops,
              title: 'Talleres cerca de ti',
              routePath: RouteNames.workshops,
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
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  color: AppColors.primaryInk,
                  size: 24,
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
