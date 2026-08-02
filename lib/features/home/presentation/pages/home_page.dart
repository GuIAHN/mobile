import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/home_filters.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../domain/entities/sort_option.dart';
import '../providers/home_providers.dart';
import '../../../ads/presentation/providers/ads_provider.dart';
import '../../../../core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/bottom_burbuja.dart';
import '../widgets/category_selector.dart';
import '../widgets/filters_sheet.dart';
import '../widgets/item_card.dart';
import '../widgets/promo_carousel.dart';
import '../widgets/request_spare_part_form.dart';
import '../../../auth/presentation/pages/profile_tab.dart';
import '../widgets/unapproved_overlay.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vehicles/domain/entities/user_car.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../../chat/presentation/pages/chat_inbox_page.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../catalog/domain/entities/specialty.dart';
import '../../../vehicles/presentation/widgets/garage_vehicle_selector_sheet.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/staggered_entrance.dart';

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
    // Auto-activar si el permiso ya fue concedido previamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialLocationPermission();
    });

    // Escuchar cambios de tipo de servicio para limpiar búsqueda y filtros.
    // Se hace aquí (fuera de build) para no mutar estado durante el build,
    // lo que corrompe el árbol semántico y lanza !semantics.parentDataDirty.
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

  // Abre la hoja de filtros y guarda el resultado.
  // Espera un frame completo antes de mostrar el modal para que el
  // frame actual (tap) termine su fase de layout/semantics sin conflictos.
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

    // Show a friendly welcome greeting if authenticated and not shown yet in this session
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
          // Barra de navegación inferior burbuja flotante
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomBurbuja(),
          ),
          // Capa de bloqueo para usuarios no aprobados (mecánicos, talleres, etc)
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
    final searchVehicle = ref.watch(searchVehicleProvider);

    final user = ref.watch(authProvider).user;
    final isConsumer = user == null || user.role.isConsumer;

    // Pre-trigger user cars loading
    ref.watch(userCarsProvider);

    return ListView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
          bottom: 120), // Espaciado extra para no tapar con la barra burbuja
      children: [
        // 1. Header (Logo + Ubicación)
        _buildHeader(),

        // 2. Carrusel de Promociones / Banners
        promosAsync.when(
          data: (promos) => Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
            child: PromoCarousel(promos: promos),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8, left: 20, right: 20),
            child: PromoSkeleton(),
          ),
          error: (error, stack) {
            print('🔥 ERROR EN CARROUSEL: $error');
            print(stack);
            return Center(child: Text('Error: $error'));
          },
        ),

        // 3. Selector de categoría
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: CategorySelector(),
        ),

        // 4. Barra de vehículo y búsqueda (solo mecánicos/talleres)
        if (!isSpareParts) ...[
          if (isConsumer) ...[
            if (searchVehicle != null)
              _buildSelectedVehicleBar(searchVehicle)
            else
              _buildSelectVehiclePromptBar(),
          ],
          _buildSearchBar(filters.activeCount),
        ],

        // Si es repuestos, mostramos el formulario de solicitud
        if (isSpareParts)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: RequestSparePartForm(
              onSubmitted: () {
                _scrollController.animateTo(
                  0.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutCubic,
                );
              },
            ),
          )
        else ...[
          // 5. Encabezado de la lista
          _buildListHeader(
              filteredItemsAsync.value?.length ?? 0, filters.activeCount > 0),

          // 6. Chips con los filtros aplicados
          if (filters.activeCount > 0) _buildActiveFilterChips(filters),

          // 7. Lista de Items filtrados
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

  Widget _buildSelectedVehicleBar(UserCar car) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.directions_car_filled_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BUSCANDO PARA:',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${car.brand} ${car.model} (${car.year})',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _abrirSelectorVehiculoSearch(),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Cambiar',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectVehiclePromptBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.directions_car_filled_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COMPATIBILIDAD:',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Selecciona tu vehículo',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _abrirSelectorVehiculoSearch(),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: AppColors.primaryMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Elegir',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirSelectorVehiculoSearch() async {
    final result = await GarageVehicleSelectorSheet.show(
      context,
      selectedCar: ref.read(searchVehicleProvider),
    );
    if (result != null) {
      ref.read(searchVehicleModelIdProvider.notifier).state = result.modelId;
      ref.read(searchVehicleProvider.notifier).state = result.car;
    }
  }

  Widget _buildHeader() {
    final isLocationShared = ref.watch(isLocationSharedProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          // Logo + Nombre de la App "GUIA HN" con toques naranja (Todo Mayúsculas)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_icon.png',
                height: 72,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(width: 10),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    const TextSpan(text: 'GU'),
                    TextSpan(
                      text: 'IA',
                      style: TextStyle(
                        color: AppColors.primary,
                        shadows: [
                          Shadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'HN',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Toggle de Compartir Ubicación
          GestureDetector(
            onTap: () => _handleLocationToggle(context),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isLocationShared ? AppColors.primaryMuted : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isLocationShared ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isLocationShared
                    ? Icons.location_on
                    : Icons.location_on_outlined,
                color: isLocationShared
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkInitialLocationPermission() async {
    final service = ref.read(locationServiceProvider);
    final permission = await service.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final isServiceEnabled = await service.isLocationServiceEnabled();
      if (isServiceEnabled) {
        ref.read(isLocationSharedProvider.notifier).state = true;
        await ref.read(userLocationProvider.notifier).updateLocation();
      }
    }
  }

  Future<void> _handleLocationToggle(BuildContext context) async {
    final isCurrentlyShared = ref.read(isLocationSharedProvider);
    if (isCurrentlyShared) {
      ref.read(isLocationSharedProvider.notifier).state = false;
      return;
    }

    final service = ref.read(locationServiceProvider);

    // 1. Verificar si el GPS está habilitado
    final isServiceEnabled = await service.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      if (!context.mounted) return;
      _showGpsDisabledDialog(context);
      return;
    }

    // 2. Verificar y solicitar permisos
    var permission = await service.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await service.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permiso de ubicación denegado por el usuario.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!context.mounted) return;
      _showSettingsRedirectDialog(context);
      return;
    }

    // 3. Activar compartir ubicación
    ref.read(isLocationSharedProvider.notifier).state = true;
    final success =
        await ref.read(userLocationProvider.notifier).updateLocation();
    if (!success) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No se pudo obtener la ubicación exacta. Usando última conocida.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showGpsDisabledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded,
                color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'GPS Desactivado',
                style: GoogleFonts.hankenGrotesk(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'El servicio de ubicación (GPS) está apagado en tu dispositivo. Puedes activarlo en tu configuración o continuar usando la última ubicación conocida.',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.hankenGrotesk(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final service = ref.read(locationServiceProvider);
                    final lastKnown = await service.getLastKnownPosition();
                    if (lastKnown != null) {
                      ref.read(isLocationSharedProvider.notifier).state = true;
                      ref.read(userLocationProvider.notifier).updateLocation();
                    } else {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'No hay ubicación conocida anterior. Activa el GPS.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Usar última',
                    style: GoogleFonts.hankenGrotesk(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSettingsRedirectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.settings_applications_rounded,
                color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Permiso de Ubicación',
                style: GoogleFonts.hankenGrotesk(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Para buscar talleres o repuestos cercanos a ti, la aplicación necesita acceder a tu ubicación. Por favor, actívala en los Ajustes del sistema.',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.hankenGrotesk(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(locationServiceProvider).openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Ir a Ajustes',
                    style: GoogleFonts.hankenGrotesk(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(int activeFilters) {
    final selectedType = ref.watch(selectedServiceTypeProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // Esquinas de 12px
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).state = val;
                },
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: false,
                  isCollapsed: true,
                  hintText: selectedType.hint,
                  hintStyle: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (searchQuery.isNotEmpty) ...[
              IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: () {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                },
                icon: const Icon(Icons.cancel_rounded,
                    color: AppColors.textDisabled, size: 18),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
            // Botón de filtros integrado en la misma barra
            Semantics(
              button: true,
              label: activeFilters > 0
                  ? 'Filtros de búsqueda, $activeFilters activos'
                  : 'Filtros de búsqueda',
              child: GestureDetector(
                onTap: _openFilters,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: activeFilters > 0
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      if (activeFilters > 0)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            width: 14,
                            height: 14,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$activeFilters',
                              style: GoogleFonts.hankenGrotesk(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader(int itemCount, bool hasActiveFilters) {
    final selectedType = ref.watch(selectedServiceTypeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '${selectedType.label} cerca de ti',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$itemCount',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (hasActiveFilters)
            GestureDetector(
              onTap: () {
                ref.read(homeFiltersProvider.notifier).state =
                    const HomeFilters();
              },
              child: Row(
                children: [
                  const Icon(Icons.close_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text(
                    'Quitar filtros',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips(HomeFilters filters) {
    final chips = <Widget>[];
    final specialtiesAsync = ref.watch(specialtiesProvider);

    void addChip(Widget content, VoidCallback onRemove) {
      chips.add(
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              content,
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.cancel_rounded,
                    size: 16, color: AppColors.textDisabled),
              ),
            ],
          ),
        ),
      );
    }

    if (filters.sortBy != SortOption.cercania) {
      addChip(
        Text(
          filters.sortBy.label,
          style: GoogleFonts.hankenGrotesk(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        () => ref.read(homeFiltersProvider.notifier).state =
            filters.copyWith(sortBy: SortOption.cercania),
      );
    }

    if (filters.radioKm != 20.0) {
      addChip(
        Text(
          '≤ ${filters.radioKm.toInt()} km',
          style: GoogleFonts.hankenGrotesk(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        () => ref.read(homeFiltersProvider.notifier).state =
            filters.copyWith(radioKm: 20.0),
      );
    }

    if (filters.minRating != 0.0) {
      addChip(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
            const SizedBox(width: 3),
            Text(
              '${filters.minRating}+',
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
        () => ref.read(homeFiltersProvider.notifier).state =
            filters.copyWith(minRating: 0.0),
      );
    }





    if (filters.specialtyIds.isNotEmpty) {
      specialtiesAsync.whenData((specialties) {
        for (final id in filters.specialtyIds) {
          final specialty = specialties.firstWhere(
            (s) => s.id == id,
            orElse: () => Specialty(id: id, name: id),
          );
          addChip(
            Text(
              specialty.name,
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            () {
              final newSpecialties = List<String>.from(filters.specialtyIds)
                ..remove(id);
              ref.read(homeFiltersProvider.notifier).state =
                  filters.copyWith(specialtyIds: newSpecialties);
            },
          );
        }
      });
    }

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
        children: chips,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: EmptyState(
        title: 'Sin resultados',
        subtitle:
            'Prueba ampliando el rango de búsqueda o modificando tus filtros.',
        icon: Icons.search_off_rounded,
        action: SizedBox(
          width: 180,
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              ref.read(homeFiltersProvider.notifier).state =
                  const HomeFilters();
              setState(() {
                _searchController.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Restablecer filtros',
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}
