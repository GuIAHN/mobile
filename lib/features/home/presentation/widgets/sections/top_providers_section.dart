import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/domain/enums/service_type.dart';
import '../../../../../core/router/route_names.dart';
import '../../../domain/entities/home_item.dart';
import '../../providers/home_providers.dart';
import '../icon_mapper.dart';
import '../../../../chat/presentation/widgets/_atoms/card_shell.dart';
import '../../../../chat/presentation/widgets/_atoms/card_tokens.dart';
import '../../../../chat/presentation/widgets/_atoms/meta_line.dart';

/// Sección destacada del home con los mejores proveedores cercanos
/// (talleres o mecánicos) en una lista vertical de ancho completo.
/// "Ver todos" navega a la pantalla completa del tipo correspondiente.
class TopProvidersSection extends ConsumerWidget {
  final ServiceType serviceType;
  final String title;
  final String routePath;

  const TopProvidersSection({
    super.key,
    required this.serviceType,
    required this.title,
    required this.routePath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(topProvidersProvider(serviceType));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push(routePath),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'Ver todos',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: itemsAsync.when(
            data: (items) => Column(
              children: [
                if (items.isEmpty)
                  const _SectionStateCard(
                    message: 'Todavía no hay talleres valorados',
                  ),
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _ProviderCard(item: items[i], rank: i + 1),
                ],
              ],
            ),
            loading: () => const Column(
              children: [
                _ProviderCardSkeleton(key: Key('top-provider-skeleton-1')),
                SizedBox(height: 12),
                _ProviderCardSkeleton(key: Key('top-provider-skeleton-2')),
                SizedBox(height: 12),
                _ProviderCardSkeleton(key: Key('top-provider-skeleton-3')),
              ],
            ),
            error: (_, __) => _SectionStateCard(
              message: 'No pudimos cargar los talleres',
              action: TextButton.icon(
                onPressed: () => ref.invalidate(homeItemsProvider(serviceType)),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final HomeItem item;
  final int rank;

  const _ProviderCard({required this.item, required this.rank});

  void _onTap(BuildContext context) {
    if (item.id == null) return;

    switch (item.type) {
      case ServiceType.mechanic:
        context.push(RouteNames.mechanicDetailPath(item.id!));
        break;
      case ServiceType.workshops:
        context.push(RouteNames.storeDetailPath(item.id!));
        break;
      case ServiceType.spareParts:
      case ServiceType.storeDashboard:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = item.photo != null && item.photo!.isNotEmpty;

    return Semantics(
      button: true,
      enabled: item.id != null,
      label: 'Ver detalles de ${item.name}, puesto $rank',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(CardTokens.radius),
        child: InkWell(
          onTap: item.id == null ? null : () => _onTap(context),
          borderRadius: BorderRadius.circular(CardTokens.radius),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(CardTokens.radius),
              border: Border.all(color: AppColors.grey100),
              boxShadow: CardTokens.shadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: 'Puesto $rank',
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$rank',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // ── Miniatura cuadrada grande ────────────────────────
                hasPhoto
                    ? CardThumb(
                        url: item.photo,
                        size: CardTokens.thumbSizeLarge,
                        fallbackIcon: getIconData(item.iconName),
                      )
                    : Container(
                        width: CardTokens.thumbSizeLarge,
                        height: CardTokens.thumbSizeLarge,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(CardTokens.thumbRadius),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primaryMuted, AppColors.grey100],
                          ),
                        ),
                        child: Icon(
                          getIconData(item.iconName),
                          size: 36,
                          color: AppColors.primary.withValues(alpha: 0.6),
                        ),
                      ),
                const SizedBox(width: 14),

                // ── Información ────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CardTokens.title.copyWith(fontSize: 15),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: item.isOpen
                                  ? AppColors.successLight
                                  : AppColors.grey100,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              item.isOpen ? 'Abierto' : 'Cerrado',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                                color: item.isOpen
                                    ? AppColors.successInk
                                    : AppColors.textMeta,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: CardTokens.tight),
                      Wrap(
                        spacing: 3,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: AppColors.warning),
                          Text(
                            item.rating.toStringAsFixed(1),
                            style: CardTokens.metaStrong,
                          ),
                          Text(
                            item.reviews > 0
                                ? '${item.reviews} reseñas'
                                : 'Sin reseñas',
                            style: CardTokens.meta,
                          ),
                          const Icon(Icons.place_outlined,
                              size: 13, color: AppColors.celesteInk),
                          Text(
                            '${item.distanceKm.toStringAsFixed(1)} km',
                            style: CardTokens.meta.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.celesteInk,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: CardTokens.gap),
                      MetaLine(
                        items: [
                          MetaItem(
                            item.especialidades.isNotEmpty
                                ? item.especialidades.take(2).join(' · ')
                                : item.detail,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionStateCard extends StatelessWidget {
  final String message;
  final Widget? action;

  const _SectionStateCard({required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.grey100),
        boxShadow: CardTokens.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: CardTokens.title.copyWith(fontSize: 15)),
          if (action != null) ...[
            const SizedBox(height: 8),
            action!,
          ],
        ],
      ),
    );
  }
}

class _ProviderCardSkeleton extends StatelessWidget {
  const _ProviderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CardTokens.radius),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: CardTokens.thumbSizeLarge,
            height: CardTokens.thumbSizeLarge,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(CardTokens.thumbRadius),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(width: 130),
                const SizedBox(height: 9),
                _bar(width: 86),
                const SizedBox(height: 9),
                _bar(width: 110),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar({required double width}) {
    return Container(
      width: width,
      height: 11,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
