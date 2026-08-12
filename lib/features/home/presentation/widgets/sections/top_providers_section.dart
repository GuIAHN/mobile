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

    // Si no hay resultados y no está cargando, ocultar la sección completa.
    final items = itemsAsync.valueOrNull;
    if (items != null && items.isEmpty) return const SizedBox.shrink();

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
              GestureDetector(
                onTap: () => context.push(routePath),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Text(
                    'Ver todos',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
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
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _ProviderCard(item: items[i]),
                ],
              ],
            ),
            loading: () => const Column(
              children: [
                _ProviderCardSkeleton(),
                SizedBox(height: 12),
                _ProviderCardSkeleton(),
                SizedBox(height: 12),
                _ProviderCardSkeleton(),
              ],
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _ProviderCard extends StatefulWidget {
  final HomeItem item;

  const _ProviderCard({required this.item});

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  bool _isPressed = false;

  void _onTap() {
    final item = widget.item;
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
    final item = widget.item;
    final hasPhoto = item.photo != null && item.photo!.isNotEmpty;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
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
                        borderRadius: BorderRadius.circular(CardTokens.thumbRadius),
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
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.isOpen ? AppColors.successLight : AppColors.grey100,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            item.isOpen ? 'Abierto' : 'Cerrado',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                              color: item.isOpen ? AppColors.successInk : AppColors.textMeta,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CardTokens.tight),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                        const SizedBox(width: 3),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: CardTokens.metaStrong,
                        ),
                        Text(' (${item.reviews})', style: CardTokens.meta),
                        const Spacer(),
                        const Icon(Icons.place_outlined, size: 13, color: AppColors.celesteInk),
                        const SizedBox(width: 2),
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
    );
  }
}

class _ProviderCardSkeleton extends StatelessWidget {
  const _ProviderCardSkeleton();

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
