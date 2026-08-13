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
import '../../../../chat/presentation/widgets/_atoms/card_tokens.dart';

const double _providerCardRadius = 10;
const double _workshopCardBaseHeight = 244;
const double _mechanicCardBaseHeight = 164;
const double _workshopMediaHeight = 128;
const double _mechanicMediaWidth = 104;

double _providerCardHeight(BuildContext context, ServiceType serviceType) {
  final scaler = MediaQuery.textScalerOf(context);
  final scale = scaler.scale(14) / 14;
  final normalizedScale = (scale - 1).clamp(0.0, 1.0);

  return switch (serviceType) {
    ServiceType.mechanic => _mechanicCardBaseHeight + normalizedScale * 120,
    ServiceType.workshops => _workshopCardBaseHeight + normalizedScale * 100,
    ServiceType.spareParts ||
    ServiceType.storeDashboard =>
      _workshopCardBaseHeight + normalizedScale * 100,
  };
}

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
    final providerNoun = _providerNoun(serviceType);

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
        itemsAsync.when(
          data: (items) => items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionStateCard(
                    message: 'Todavía no hay $providerNoun valorados',
                  ),
                )
              : _ProviderSequence(
                  items: items,
                  serviceType: serviceType,
                ),
          loading: () => _ProviderSkeletonSequence(serviceType: serviceType),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SectionStateCard(
              message: 'No pudimos cargar los $providerNoun',
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

class _ProviderSequence extends StatelessWidget {
  final List<HomeItem> items;
  final ServiceType serviceType;

  const _ProviderSequence({
    required this.items,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - 48).clamp(300.0, 340.0).toDouble();
        return SizedBox(
          height: _providerCardHeight(context, serviceType),
          child: ListView.separated(
            key: const Key('top-providers-horizontal-list'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) => SizedBox(
              width: cardWidth,
              child: _ProviderCard(item: items[index]),
            ),
          ),
        );
      },
    );
  }
}

String _providerNoun(ServiceType serviceType) {
  return switch (serviceType) {
    ServiceType.mechanic => 'mecánicos',
    ServiceType.workshops => 'talleres',
    ServiceType.spareParts || ServiceType.storeDashboard => 'proveedores',
  };
}

class _ProviderCard extends StatelessWidget {
  final HomeItem item;

  const _ProviderCard({required this.item});

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
    final onTap = item.id == null ? null : () => _onTap(context);
    final radius = BorderRadius.circular(_providerCardRadius);

    return Semantics(
      container: true,
      button: true,
      enabled: item.id != null,
      label: 'Ver detalles de ${item.name}',
      excludeSemantics: true,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: CardTokens.shadow,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: SizedBox(
              height: _providerCardHeight(context, item.type),
              child: item.type == ServiceType.workshops
                  ? _WorkshopProviderBody(item: item)
                  : _MechanicProviderBody(item: item),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkshopProviderBody extends StatelessWidget {
  final HomeItem item;

  const _WorkshopProviderBody({required this.item});

  @override
  Widget build(BuildContext context) {
    final id = item.id ?? item.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          key: Key('top-provider-media-$id'),
          height: _workshopMediaHeight,
          child: _ProviderMedia(item: item),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CardTokens.title.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _RatingSummary(item: item),
                    _DistanceSummary(item: item),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _AvailabilityLine(isOpen: item.isOpen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SpecialtyText(item: item),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MechanicProviderBody extends StatelessWidget {
  final HomeItem item;

  const _MechanicProviderBody({required this.item});

  @override
  Widget build(BuildContext context) {
    final id = item.id ?? item.name;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          key: Key('top-provider-media-$id'),
          width: _mechanicMediaWidth,
          child: _ProviderMedia(item: item),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CardTokens.title.copyWith(fontSize: 15),
                ),
                const SizedBox(height: CardTokens.tight),
                _RatingSummary(item: item, fillAvailableWidth: true),
                const SizedBox(height: 2),
                _DistanceSummary(item: item, fillAvailableWidth: true),
                const SizedBox(height: CardTokens.gap),
                _AvailabilityLine(isOpen: item.isOpen),
                const SizedBox(height: 6),
                _SpecialtyText(item: item),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final HomeItem item;
  final bool fillAvailableWidth;

  const _RatingSummary({
    required this.item,
    this.fillAvailableWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final reviews = Text(
      item.reviews > 0 ? '${item.reviews} reseñas' : 'Sin reseñas',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CardTokens.meta,
    );

    return Row(
      mainAxisSize: fillAvailableWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        const Icon(
          Icons.star_rounded,
          size: 14,
          color: AppColors.warning,
        ),
        const SizedBox(width: 3),
        Text(item.rating.toStringAsFixed(1), style: CardTokens.metaStrong),
        const SizedBox(width: 4),
        if (fillAvailableWidth)
          Expanded(child: reviews)
        else
          Flexible(child: reviews),
      ],
    );
  }
}

class _DistanceSummary extends StatelessWidget {
  final HomeItem item;
  final bool fillAvailableWidth;

  const _DistanceSummary({
    required this.item,
    this.fillAvailableWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final distance = Text(
      item.distanceKm == null
          ? 'Distancia no disponible'
          : '${item.distanceKm!.toStringAsFixed(1)} km',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CardTokens.meta.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.celesteInk,
      ),
    );

    return Row(
      mainAxisSize: fillAvailableWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        const Icon(
          Icons.place_outlined,
          size: 13,
          color: AppColors.celesteInk,
        ),
        const SizedBox(width: 3),
        if (fillAvailableWidth)
          Expanded(child: distance)
        else
          Flexible(child: distance),
      ],
    );
  }
}

class _SpecialtyText extends StatelessWidget {
  final HomeItem item;

  const _SpecialtyText({required this.item});

  @override
  Widget build(BuildContext context) {
    return Text(
      item.especialidades.isNotEmpty
          ? item.especialidades.take(2).join(' · ')
          : item.detail,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CardTokens.meta,
    );
  }
}

class _ProviderMedia extends StatelessWidget {
  final HomeItem item;

  const _ProviderMedia({required this.item});

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.grey50),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child:
                SizedBox(width: 4, child: ColoredBox(color: AppColors.primary)),
          ),
          Center(
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                getIconData(item.iconName),
                size: 28,
                color: AppColors.primaryInk,
              ),
            ),
          ),
        ],
      ),
    );

    Widget photo() {
      if (item.photo == null || item.photo!.isEmpty) return fallback;
      return Image.network(
        item.photo!,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    final id = item.id ?? item.name;
    if (item.type == ServiceType.workshops) {
      return SizedBox(
        key: Key('top-provider-workshop-photo-$id'),
        width: double.infinity,
        height: _workshopMediaHeight,
        child: photo(),
      );
    }

    return Center(
      child: ClipOval(
        child: SizedBox(
          key: Key('top-provider-mechanic-avatar-$id'),
          width: 76,
          height: 76,
          child: photo(),
        ),
      ),
    );
  }
}

class _AvailabilityLine extends StatelessWidget {
  final bool? isOpen;

  const _AvailabilityLine({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = switch (isOpen) {
      true => AppColors.successInk,
      false => AppColors.textMeta,
      null => AppColors.textMeta,
    };
    final label = switch (isOpen) {
      true => 'Abierto',
      false => 'Cerrado',
      null => 'Horario no disponible',
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(_providerCardRadius),
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
  final ServiceType serviceType;
  final int index;

  const _ProviderCardSkeleton({
    super.key,
    required this.serviceType,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: _providerCardHeight(context, serviceType),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_providerCardRadius),
      ),
      child: serviceType == ServiceType.workshops
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  key: Key(
                    'top-provider-skeleton-media-${serviceType.name}-$index',
                  ),
                  height: _workshopMediaHeight,
                  child: const ColoredBox(color: AppColors.grey100),
                ),
                Expanded(child: _SkeletonDetails(barBuilder: _bar)),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: _mechanicMediaWidth,
                  child: Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: AppColors.grey100,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Expanded(child: _SkeletonDetails(barBuilder: _bar)),
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

class _SkeletonDetails extends StatelessWidget {
  final Widget Function({required double width}) barBuilder;

  const _SkeletonDetails({required this.barBuilder});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          barBuilder(width: 130),
          const SizedBox(height: 9),
          barBuilder(width: 86),
          const SizedBox(height: 9),
          barBuilder(width: 110),
        ],
      ),
    );
  }
}

class _ProviderSkeletonSequence extends StatelessWidget {
  final ServiceType serviceType;

  const _ProviderSkeletonSequence({required this.serviceType});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - 48).clamp(300.0, 340.0).toDouble();
        return SizedBox(
          height: _providerCardHeight(context, serviceType),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) => SizedBox(
              width: cardWidth,
              child: _ProviderCardSkeleton(
                key: Key('top-provider-skeleton-${index + 1}'),
                serviceType: serviceType,
                index: index + 1,
              ),
            ),
          ),
        );
      },
    );
  }
}
