import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
import '../../../../shared/widgets/skeleton_loader.dart';

// Componentes del Home (hub de navegación)
import '../widgets/header/home_header_expanded.dart';
import '../widgets/sections/top_providers_section.dart';
import '../widgets/sections/my_garage_section.dart';
import '../widgets/store_dashboard/store_dashboard_view.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/providers/current_user_provider.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          authState.isAuthenticated &&
          user != null &&
          !ref.read(welcomeShownProvider)) {
        ref.read(welcomeShownProvider.notifier).state = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.waving_hand_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '¡Hola, ${user.name}!',
                      style: GoogleFonts.hankenGrotesk(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 2000),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            margin: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.md,
            ),
          ),
        );
      }
    });

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
    // La tienda no tiene garage: aunque isDashboardSelected quede desactualizado
    // (ej. al volver de la lista de mecánicos/talleres), el rol manda.
    final showGarage =
        !isConsumer && !isDashboardSelected && !currentRole.isStore;
    final promoSection = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: promosAsync.when(
        data: (promos) => PromoCarousel(promos: promos),
        loading: () => const PromoSkeleton(),
        error: (error, stack) => const SizedBox.shrink(),
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
        const HomeHeaderExpanded(),

        if (showGarage) ...[
          // ── Mi garage: vehículos del usuario con acceso rápido ─────────
          const SizedBox(height: 20),
          const MyGarageSection(),

          // ── Publicidad ──────────────────────────────────────────────
          const SizedBox(height: 20),
          promoSection,
        ],

        if (isConsumer)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              '¿Qué necesitas hoy?',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),

        // ── Tarjetas de categorías estilo Pedidos Ya (redirigen a flujos) ──
        Padding(
          padding: EdgeInsets.fromLTRB(20, isConsumer ? 0 : 20, 20, 16),
          child: const CategoryGrid(),
        ),

        if (isConsumer) promoSection,

        if (isDashboardSelected && currentRole.isStore)
          // Dashboard para usuarios tipo tienda
          const StoreDashboardView()
        else if (isConsumer) ...[
          if (allowedTypes.contains(ServiceType.workshops)) ...[
            const SizedBox(height: 8),
            const TopProvidersSection(
              serviceType: ServiceType.workshops,
              title: 'Talleres mejor valorados',
              routePath: RouteNames.workshops,
            ),
          ],
          if (allowedTypes.contains(ServiceType.mechanic)) ...[
            const SizedBox(height: 24),
            const TopProvidersSection(
              serviceType: ServiceType.mechanic,
              title: 'Mecánicos mejor valorados',
              routePath: RouteNames.mechanics,
            ),
          ],
        ] else ...[
          // ── Top mecánicos cercanos ────────────────────────────────
          if (allowedTypes.contains(ServiceType.mechanic)) ...[
            const SizedBox(height: 8),
            const TopProvidersSection(
              serviceType: ServiceType.mechanic,
              title: 'Mecánicos cerca de ti',
              routePath: RouteNames.mechanics,
            ),
          ],

          // ── Top talleres cercanos ─────────────────────────────────
          if (allowedTypes.contains(ServiceType.workshops)) ...[
            const SizedBox(height: 24),
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
