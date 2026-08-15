import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/provider_detail.dart';
import '../providers/home_providers.dart';
import '../widgets/provider_detail_widgets.dart';

class StoreDetailPage extends ConsumerWidget {
  final String storeId;
  final ServiceType serviceType;

  const StoreDetailPage({
    super.key,
    required this.storeId,
    this.serviceType = ServiceType.workshops,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (id: storeId, type: serviceType);
    final detailAsync = ref.watch(providerDetailProvider(args));
    final isStore = serviceType == ServiceType.spareParts;
    final providerLabel = isStore ? 'tienda' : 'taller';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        loading: () => const DetailSkeleton(),
        error: (e, _) => DetailErrorView(
          title: 'No se pudo cargar la $providerLabel',
          message: e.toString(),
          onRetry: () => ref.invalidate(providerDetailProvider(args)),
        ),
        data: (detail) {
          final hasContact = detail.telefono != null;
          final hasLocation = detail.direccion != null ||
              detail.lat != null ||
              detail.lng != null;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: AppColors.background,
                surfaceTintColor: AppColors.background,
                leading: const DetailBackButton(),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: DetailHeaderBackground(
                    heroTag: 'provider-avatar-$storeId',
                    nombre: detail.nombre,
                    tipoLabel:
                        isStore ? 'Tienda de repuestos' : 'Taller Mecánico',
                    icono: isStore
                        ? Icons.storefront_rounded
                        : Icons.warehouse_rounded,
                    verified: detail.verified,
                    photoUrl: detail.photo,
                  ),
                ),
              ),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    DetailHeroStatsCard(
                      rating: detail.rating,
                      ratingCount: detail.ratingCount,
                      distanciaKm: detail.distanciaKm,
                      tarifa: detail.tarifa,
                    ),
                    const SizedBox(height: 24),
                    if (detail.hasDelivery) ...[
                      const _DeliveryBadge(),
                      const SizedBox(height: 24),
                    ],
                    if (detail.especialidades.isNotEmpty) ...[
                      const DetailSectionTitle(title: 'Servicios que ofrece'),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: detail.especialidades
                            .map((e) => DetailChip(label: e))
                            .toList(),
                      ),
                      const SizedBox(height: 28),
                    ],
                    if (detail.categorias.isNotEmpty) ...[
                      const DetailSectionTitle(title: 'Catálogo de repuestos'),
                      const SizedBox(height: 14),
                      ...detail.categorias
                          .map((c) => _CategoryCard(category: c)),
                      const SizedBox(height: 16),
                    ],
                    DetailSectionTitle(title: 'Sobre la $providerLabel'),
                    const SizedBox(height: 14),
                    DetailDescriptionCard(
                      text: detail.descripcion ?? '',
                      title: isStore
                          ? 'PRESENTACIÓN DE LA TIENDA'
                          : 'PRESENTACIÓN DEL TALLER',
                    ),
                    const SizedBox(height: 28),
                    if (hasLocation) ...[
                      DetailSectionTitle(
                        title: 'Ubicación de la $providerLabel',
                      ),
                      const SizedBox(height: 14),
                      DetailLocationCard(
                        direccion: detail.direccion,
                        lat: detail.lat,
                        lng: detail.lng,
                      ),
                      const SizedBox(height: 28),
                    ],
                    if (hasContact) ...[
                      const DetailSectionTitle(title: 'Contacto'),
                      const SizedBox(height: 14),
                      if (detail.telefono != null) ...[
                        DetailContactTile(
                          icon: Icons.phone_rounded,
                          label: 'Llamar por teléfono',
                          value: detail.telefono!,
                          color: AppColors.success,
                          semanticsHint: 'Toca para llamar',
                          onTap: () =>
                              ContactActions.call(context, detail.telefono!),
                        ),
                        DetailContactTile(
                          icon: Icons.chat_bubble_rounded,
                          label: 'WhatsApp',
                          value: detail.telefono!,
                          color: const Color(0xFF25D366),
                          semanticsHint: 'Toca para escribir por WhatsApp',
                          onTap: () => ContactActions.whatsapp(
                              context, detail.telefono!),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Sub-widgets propios de esta pantalla ──────────────────────────────────

class _DeliveryBadge extends StatelessWidget {
  const _DeliveryBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.successLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ofrece delivery a domicilio',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de categoría del catálogo: nombre, precio "desde" y marcas cubiertas.
class _CategoryCard extends StatelessWidget {
  final ProviderCategory category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.settings_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (category.startingPrice != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Desde ${Formatters.currencyCompact(category.startingPrice!)}',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (category.brands.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: category.brands
                  .map(
                    (b) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        b,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
