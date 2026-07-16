import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  const StoreDetailPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (id: storeId, type: ServiceType.workshops);
    final detailAsync = ref.watch(providerDetailProvider(args));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        loading: () => const DetailSkeleton(),
        error: (e, _) => DetailErrorView(
          title: 'No se pudo cargar el taller',
          message: e.toString(),
          onRetry: () => ref.invalidate(providerDetailProvider(args)),
        ),
        data: (detail) {
          final hasContact = detail.telefono != null || detail.email != null;

          final stats = <DetailStat>[
            if (detail.rating != null)
              DetailStat(
                icon: Icons.star_rounded,
                color: const Color(0xFFF59E0B),
                value: detail.rating!.toStringAsFixed(1),
                label: 'Rating',
              ),
            if (detail.distanciaKm != null)
              DetailStat(
                icon: Icons.near_me_rounded,
                color: AppColors.primary,
                value: '${detail.distanciaKm!.toStringAsFixed(1)} km',
                label: 'Distancia',
              ),
            if (detail.tarifa != null)
              DetailStat(
                icon: Icons.payments_rounded,
                color: AppColors.success,
                value: '${Formatters.currencyCompact(detail.tarifa!)}/h',
                label: 'Tarifa',
              ),
          ];

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
                    tipoLabel: 'Taller Mecánico',
                    icono: Icons.warehouse_rounded,
                    verified: detail.verified,
                  ),
                ),
              ),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (stats.isNotEmpty) ...[
                      DetailStatsCard(stats: stats),
                      const SizedBox(height: 20),
                    ],

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

                    if (detail.descripcion != null &&
                        detail.descripcion!.isNotEmpty) ...[
                      const DetailSectionTitle(title: 'Sobre el taller'),
                      const SizedBox(height: 14),
                      DetailDescriptionCard(text: detail.descripcion!),
                      const SizedBox(height: 28),
                    ],

                    if (hasContact || detail.direccion != null) ...[
                      const DetailSectionTitle(title: 'Contacto y ubicación'),
                      const SizedBox(height: 14),
                      if (detail.telefono != null)
                        DetailContactTile(
                          icon: Icons.phone_rounded,
                          label: 'Teléfono',
                          value: detail.telefono!,
                          color: AppColors.success,
                          semanticsHint: 'Toca para llamar',
                          onTap: () =>
                              ContactActions.call(context, detail.telefono!),
                        ),
                      if (detail.email != null)
                        DetailContactTile(
                          icon: Icons.email_rounded,
                          label: 'Correo',
                          value: detail.email!,
                          color: AppColors.tertiary,
                          semanticsHint: 'Toca para enviar un correo',
                          onTap: () =>
                              ContactActions.email(context, detail.email!),
                        ),
                      if (detail.direccion != null)
                        DetailContactTile(
                          icon: Icons.location_on_rounded,
                          label: 'Dirección',
                          value: detail.direccion!,
                          color: AppColors.primary,
                          semanticsHint: 'Toca para copiar la dirección',
                          onTap: () async {
                            await Clipboard.setData(
                                ClipboardData(text: detail.direccion!));
                            HapticFeedback.mediumImpact();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Dirección copiada al portapapeles',
                                  style: GoogleFonts.hankenGrotesk(
                                      fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: AppColors.secondary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                    ],

                    if (hasContact)
                      DetailCtaButton(
                        label: 'Contactar',
                        icon: Icons.forum_rounded,
                        onPressed: () => ContactSheet.show(
                          context,
                          nombre: detail.nombre,
                          telefono: detail.telefono,
                          email: detail.email,
                        ),
                      ),
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
