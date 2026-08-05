import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/home_filters.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../providers/home_providers.dart';
import '../../../ads/presentation/providers/ads_provider.dart';
import '../widgets/bottom_burbuja.dart';
import '../widgets/category_selector.dart';
import '../widgets/filters_sheet.dart';
import '../widgets/item_card.dart';
import '../widgets/promo_carousel.dart';
import '../../../auth/presentation/pages/profile_tab.dart';
import '../widgets/unapproved_overlay.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../../chat/presentation/pages/chat_inbox_page.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/staggered_entrance.dart';

// Import new components
import '../widgets/home_header.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/vehicle_compatibility_bar.dart';
import '../widgets/spare_parts_cta.dart';
import '../widgets/home_list_header.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  ProviderSubscription<ServiceType>? _serviceTypeSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _serviceTypeSub = ref.listenManual<ServiceType>(
        selectedServiceTypeProvider,
        (previous, next) {
          if (previous != null && previous != next) {
            _searchController.clear();
            ref.read(searchQueryProvider.notifier).state = '';
            ref.read(homeFiltersProvider.notifier).state = const HomeFilters();
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _serviceTypeSub?.close();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final currentFilters = ref.read(homeFiltersProvider);
    final serviceType = ref.read(selectedServiceTypeProvider);
    final result = await showModalBottomSheet<HomeFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
      ),
      builder: (_) => FiltersSheet(
        initialFilters: currentFilters,
        serviceType: serviceType,
      ),
    );

    if (result != null) {
      ref.read(homeFiltersProvider.notifier).state = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(homeTabProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && authState.isAuthenticated && user != null && !ref.read(welcomeShownProvider)) {
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
              bottom: 96,
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: activeTab == 0
                  ? _buildHomeTab()
                  : activeTab == 1
                      ? const ChatInboxPage()
                      : const ProfileTab(),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomBurbuja(),
          ),
          if (user != null && !user.approved)
            const Positioned.fill(
              child: UnapprovedOverlay(),
            ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final selectedType = ref.watch(selectedServiceTypeProvider);
    return _buildBody(selectedType);
  }

  Widget _buildBody(ServiceType selectedType) {
    final promosAsync = ref.watch(adsAsPromosProvider(selectedType));
    final filteredItemsAsync = ref.watch(filteredHomeItemsProvider);
    final filters = ref.watch(homeFiltersProvider);
    final isSpareParts = selectedType == ServiceType.spareParts;

    final user = ref.watch(authProvider).user;
    final isConsumer = user == null || user.role.isConsumer;

    ref.watch(userCarsProvider);

    return ListView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        const HomeHeader(),

        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: CategorySelector(),
        ),

        if (!isSpareParts)
          HomeSearchBar(
            searchController: _searchController,
            activeFilters: filters.activeCount,
            onFilterTap: _openFilters,
          ),

        promosAsync.when(
          data: (promos) => Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12, left: 20, right: 20),
            child: PromoCarousel(promos: promos),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
            child: PromoSkeleton(),
          ),
          error: (error, stack) {
            return Center(child: Text('Error: $error'));
          },
        ),

        if (isSpareParts)
          SparePartsCta(
            onSubmitted: () {
              _scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
              );
            },
          ),

        if (!isSpareParts && isConsumer) const VehicleCompatibilityBar(),

        if (!isSpareParts) ...[
          HomeListHeader(
            itemCount: filteredItemsAsync.value?.length ?? 0,
            hasActiveFilters: filters.activeCount > 0,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: filteredItemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyState();
                }
                return Column(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      StaggeredEntrance(
                        index: i,
                        child: ItemCard(item: items[i]),
                      ),
                  ],
                );
              },
              loading: () => const Column(
                children: [
                  ItemCardSkeleton(),
                  ItemCardSkeleton(),
                  ItemCardSkeleton(),
                ],
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Text(
                  'Error al cargar: $err',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: EmptyState(
        title: 'Sin resultados',
        subtitle: 'Prueba ampliando el rango de búsqueda o modificando tus filtros.',
        icon: Icons.search_off_rounded,
        action: SizedBox(
          width: 180,
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              ref.read(homeFiltersProvider.notifier).state = const HomeFilters();
              setState(() {
                _searchController.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Restablecer filtros',
              style: GoogleFonts.hankenGrotesk(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}
