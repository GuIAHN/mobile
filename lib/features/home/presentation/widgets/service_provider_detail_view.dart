import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../reviews/presentation/providers/reviews_providers.dart';
import '../../../reviews/presentation/widgets/provider_review_action_card.dart';
import '../../../reviews/presentation/widgets/provider_reviews_button.dart';
import '../../domain/entities/provider_detail.dart';
import '../providers/home_providers.dart';
import 'provider_detail_widgets.dart';
import 'provider_photo.dart';

/// Detalle compacto para mecánicos y talleres.
///
/// Mantiene la información esencial en una sola ficha y desplaza el mapa y el
/// contenido largo a sheets bajo demanda. Las acciones de contacto permanecen
/// visibles sin ocupar espacio dentro del scroll.
class ServiceProviderDetailView extends ConsumerWidget {
  final ProviderDetail detail;
  final String heroTag;

  const ServiceProviderDetailView({
    super.key,
    required this.detail,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = detail.telefono?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;
    final compactHero = MediaQuery.sizeOf(context).height < 760;
    final selectedVehicle = ref.watch(searchVehicleProvider);

    Future<void> contact(String channel) async {
      HapticFeedback.lightImpact();
      await registerProviderContact(
        ref,
        providerProfileId: detail.id,
        channel: channel,
      );
      if (!context.mounted) return;
      if (channel == 'PHONE') {
        await ContactActions.call(context, phone!);
      } else {
        await ContactActions.whatsapp(
          context,
          phone!,
          message: ContactActions.providerInquiryMessage(
            vehicle: selectedVehicle,
          ),
        );
      }
    }

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            key: const Key('service-provider-detail-scroll'),
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: compactHero ? 228 : 252,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.primary,
                surfaceTintColor: Colors.transparent,
                foregroundColor: Colors.white,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                leadingWidth: 64,
                leading: const DetailBackButton(),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  stretchModes: const [StretchMode.zoomBackground],
                  background: _ProviderHero(
                    detail: detail,
                    heroTag: heroTag,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.lg,
                    AppSpacing.screenHorizontal,
                    AppSpacing.xl3,
                  ),
                  child: Column(
                    children: [
                      _ProviderOverviewCard(detail: detail),
                      if (detail.userId != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        ProviderReviewsButton(
                          targetId: detail.userId!,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ProviderReviewActionCard(
                          targetId: detail.userId!,
                          providerProfileId: detail.id,
                          providerName: detail.nombre,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasPhone)
          _ContactActionBar(
            phone: phone,
            onCall: () => contact('PHONE'),
            onWhatsApp: () => contact('WHATSAPP'),
          ),
      ],
    );
  }
}

class _ProviderHero extends StatelessWidget {
  final ProviderDetail detail;
  final String heroTag;

  const _ProviderHero({required this.detail, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final photo = detail.photo?.trim();

    return Stack(
      key: const Key('service-provider-hero'),
      fit: StackFit.expand,
      children: [
        Hero(
          tag: heroTag,
          child: ProviderPhoto(
            photoUrl: photo,
            providerName: detail.nombre,
            networkKey: const Key('service-provider-hero-photo'),
            loadingFallback: _HeroFallback(
              icon: detail.esTaller ? AppIcons.workshop : AppIcons.mechanic,
              showProgress: true,
            ),
            fallback: _HeroFallback(
              key: const Key('service-provider-hero-fallback'),
              icon: detail.esTaller ? AppIcons.workshop : AppIcons.mechanic,
            ),
          ),
        ),
        if (showsProviderImage(
          photoUrl: photo,
        ))
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x52000000),
                  Color(0x00000000),
                  Color(0x70000000),
                ],
                stops: [0, 0.48, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        Positioned(
          left: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppLineIcon(
                  detail.esTaller ? AppIcons.workshop : AppIcons.mechanic,
                  size: AppIconSize.inline,
                  color: AppColors.primaryInk,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  detail.esTaller ? 'Taller mecánico' : 'Mecánico',
                  style: AppTypography.label.copyWith(
                    color: AppColors.primaryInk,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroFallback extends StatelessWidget {
  final IconData icon;
  final bool showProgress;

  const _HeroFallback({
    super.key,
    required this.icon,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AppLineIcon(
              icon,
              size: AppIconSize.hero,
              color: Colors.white,
            ),
          ),
          if (showProgress)
            const Positioned(
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: SizedBox.square(
                dimension: AppSpacing.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProviderOverviewCard extends StatelessWidget {
  final ProviderDetail detail;

  const _ProviderOverviewCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final description = detail.descripcion?.trim();
    final hasDescription = description != null && description.isNotEmpty;
    final hasLocation = (detail.direccion?.trim().isNotEmpty ?? false) ||
        detail.lat != null ||
        detail.lng != null;
    final hasPhone = detail.telefono?.trim().isNotEmpty ?? false;

    return Container(
      key: const Key('service-provider-overview-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppDecorations.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  detail.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h1,
                ),
              ),
              if (detail.verified) ...[
                const SizedBox(width: AppSpacing.sm),
                Semantics(
                  label: 'Perfil verificado',
                  child: const AppLineIcon(
                    AppIcons.verified,
                    size: AppIconSize.leading,
                    color: AppColors.celesteInk,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _ProviderMetrics(detail: detail),
          if (hasDescription) ...[
            const SizedBox(height: AppSpacing.lg),
            _ProviderIntroduction(
              description: description,
              isWorkshop: detail.esTaller,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          _CompactInfoRow(
            key: const Key('service-provider-services-row'),
            icon: AppIcons.services,
            title: 'Servicios',
            value: _specialtiesSummary(detail.especialidades),
            enabled: detail.especialidades.isNotEmpty,
            onTap: detail.especialidades.isEmpty
                ? null
                : () => _showServicesSheet(context, detail.especialidades),
          ),
          const Divider(height: 1, color: AppColors.border),
          _CompactInfoRow(
            key: const Key('service-provider-location-row'),
            icon: AppIcons.location,
            title: 'Ubicación',
            value: _locationSummary(detail),
            enabled: hasLocation,
            onTap:
                hasLocation ? () => _showLocationSheet(context, detail) : null,
          ),
          if (!hasPhone) ...[
            const Divider(height: 1, color: AppColors.border),
            const _CompactInfoRow(
              icon: AppIcons.call,
              title: 'Contacto',
              value: 'El proveedor aún no publicó un teléfono',
              enabled: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProviderIntroduction extends StatelessWidget {
  final String description;
  final bool isWorkshop;

  const _ProviderIntroduction({
    required this.description,
    required this.isWorkshop,
  });

  @override
  Widget build(BuildContext context) {
    final title = isWorkshop ? 'Sobre el taller' : 'Sobre el mecánico';
    final textStyle = AppTypography.bodySm.copyWith(height: 1.5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: description, style: textStyle),
          maxLines: 3,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth - AppSpacing.lg * 2);
        final isOverflowing = textPainter.didExceedMaxLines;

        return Semantics(
          container: true,
          label: '$title. $description',
          child: Container(
            key: const Key('service-provider-presentation-card'),
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              isOverflowing ? AppSpacing.xs : AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppLineIcon(
                      AppIcons.presentation,
                      size: AppIconSize.inline,
                      color: AppColors.primaryInk,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(title, style: AppTypography.label),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  key: const Key('service-provider-presentation-preview'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
                if (isOverflowing)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const Key('service-provider-presentation-more'),
                      onPressed: () => _showAboutSheet(
                        context,
                        title,
                        description,
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(
                          0,
                          AppSpacing.buttonHeightLg,
                        ),
                        padding: const EdgeInsets.only(
                          right: AppSpacing.sm,
                        ),
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text('Leer presentación'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProviderMetrics extends StatelessWidget {
  final ProviderDetail detail;

  const _ProviderMetrics({required this.detail});

  @override
  Widget build(BuildContext context) {
    final hasRating =
        detail.rating != null && detail.rating! > 0 && detail.ratingCount > 0;
    final items = [
      _MetricData(
        icon: AppIcons.rating,
        iconColor: AppColors.warningInk,
        value: hasRating ? detail.rating!.toStringAsFixed(1) : 'Nuevo',
        label: hasRating
            ? '${detail.ratingCount} ${detail.ratingCount == 1 ? 'reseña' : 'reseñas'}'
            : 'Sin reseñas',
      ),
      _MetricData(
        icon: AppIcons.distance,
        iconColor: AppColors.primaryInk,
        value: detail.distanciaKm != null
            ? '${detail.distanciaKm!.toStringAsFixed(1)} km'
            : 'Sin dato',
        label: 'Distancia',
      ),
      _MetricData(
        icon: AppIcons.price,
        iconColor: AppColors.successInk,
        value: detail.tarifa != null && detail.tarifa! > 0
            ? Formatters.currencyCompact(detail.tarifa!)
            : 'Consultar',
        label: detail.tarifa != null && detail.tarifa! > 0
            ? 'Tarifa / h'
            : 'Precios',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        if (constraints.maxWidth < 320 || textScale >= 1.6) {
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final item in items)
                SizedBox(
                  width: (constraints.maxWidth - AppSpacing.sm) / 2,
                  child: _MetricTile(data: item, horizontal: true),
                ),
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                Expanded(child: _MetricTile(data: items[index])),
                if (index < items.length - 1)
                  const VerticalDivider(
                    width: AppSpacing.lg,
                    thickness: 1,
                    color: AppColors.border,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MetricData {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _MetricData({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });
}

class _MetricTile extends StatelessWidget {
  final _MetricData data;
  final bool horizontal;

  const _MetricTile({required this.data, this.horizontal = false});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          horizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          data.value,
          textAlign: horizontal ? TextAlign.left : TextAlign.center,
          style: AppTypography.title,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          data.label,
          textAlign: horizontal ? TextAlign.left : TextAlign.center,
          style: AppTypography.meta,
        ),
      ],
    );

    return Semantics(
      label: '${data.value}, ${data.label}',
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.buttonHeightMd),
        padding:
            horizontal ? const EdgeInsets.all(AppSpacing.sm) : EdgeInsets.zero,
        decoration: horizontal
            ? BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              )
            : null,
        child: horizontal
            ? Row(
                children: [
                  AppLineIcon(
                    data.icon,
                    size: AppIconSize.action,
                    color: data.iconColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: content),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLineIcon(
                    data.icon,
                    size: AppIconSize.action,
                    color: data.iconColor,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  content,
                ],
              ),
      ),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool enabled;
  final VoidCallback? onTap;

  const _CompactInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: enabled,
      label: '$title. $value',
      hint: enabled ? 'Toca para ver el detalle' : null,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(minHeight: AppSpacing.buttonHeightLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: AppSpacing.xl3,
                  child: AppLineIcon(
                    icon,
                    color: enabled
                        ? AppColors.primaryInk
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.label),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm,
                      ),
                    ],
                  ),
                ),
                if (enabled) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const AppLineIcon(
                    AppIcons.next,
                    size: AppIconSize.action,
                    color: AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactActionBar extends StatelessWidget {
  final String phone;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  const _ContactActionBar({
    required this.phone,
    required this.onCall,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final useVerticalLayout =
        MediaQuery.textScalerOf(context).scale(1) >= 1.6 ||
            MediaQuery.sizeOf(context).width < 340;
    final call = _ContactButton(
      key: const Key('service-provider-call'),
      icon: AppIcons.call,
      label: 'Llamar',
      semanticsLabel: 'Llamar al $phone',
      onPressed: onCall,
      primary: false,
    );
    final whatsapp = _ContactButton(
      key: const Key('service-provider-whatsapp'),
      icon: AppIcons.message,
      label: 'WhatsApp',
      semanticsLabel: 'Escribir por WhatsApp al $phone',
      onPressed: onWhatsApp,
      primary: true,
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        key: const Key('service-provider-contact-bar'),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: AppDecorations.raised,
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: useVerticalLayout
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    call,
                    const SizedBox(height: AppSpacing.sm),
                    whatsapp,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: call),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: whatsapp),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String semanticsLabel;
  final VoidCallback onPressed;
  final bool primary;

  const _ContactButton({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.onPressed,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLineIcon(icon, size: AppIconSize.action),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              color: primary ? AppColors.textOnPrimary : AppColors.primaryInk,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: SizedBox(
        width: double.infinity,
        height: AppSpacing.buttonHeightLg,
        child: primary
            ? ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
                child: child,
              )
            : OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryInk,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
                child: child,
              ),
      ),
    );
  }
}

String _specialtiesSummary(List<String> specialties) {
  if (specialties.isEmpty) return 'Servicios por confirmar';
  if (specialties.length == 1) return specialties.first;
  if (specialties.length == 2) return specialties.join(' · ');
  return '${specialties.take(2).join(' · ')} · +${specialties.length - 2}';
}

String _locationSummary(ProviderDetail detail) {
  final address = detail.direccion?.trim();
  if (address != null && address.isNotEmpty) return address;
  if (detail.lat != null && detail.lng != null) {
    return '${detail.lat!.toStringAsFixed(4)}, ${detail.lng!.toStringAsFixed(4)}';
  }
  return 'Ubicación por confirmar';
}

Future<void> _showServicesSheet(
  BuildContext context,
  List<String> specialties,
) {
  return _showDetailSheet(
    context,
    title: 'Servicios que ofrece',
    child: _ServicesSheetContent(specialties: specialties),
  );
}

Future<void> _showAboutSheet(
  BuildContext context,
  String title,
  String description,
) {
  return _showDetailSheet(
    context,
    title: title,
    child: Text(
      description,
      key: const Key('service-provider-presentation-full'),
      style: AppTypography.body,
    ),
  );
}

Future<void> _showLocationSheet(
  BuildContext context,
  ProviderDetail detail,
) {
  return _showDetailSheet(
    context,
    title: 'Ubicación',
    maxHeightFactor: 0.82,
    child: DetailLocationCard(
      direccion: detail.direccion,
      lat: detail.lat,
      lng: detail.lng,
      embedded: true,
    ),
  );
}

Future<void> _showDetailSheet(
  BuildContext context, {
  required String title,
  required Widget child,
  double maxHeightFactor = 0.72,
}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    sheetAnimationStyle: AnimationStyle(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
      reverseDuration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
    ),
    builder: (context) => ConstrainedBox(
      key: const Key('provider-detail-sheet'),
      constraints: BoxConstraints(
        minWidth: MediaQuery.sizeOf(context).width,
        maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
      ),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppDecorations.sheet),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: AppSpacing.xl4,
              height: AppSpacing.xs,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xl6),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTypography.h2,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      key: const Key('provider-detail-sheet-close'),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Cerrar',
                      constraints: const BoxConstraints(
                        minWidth: AppSpacing.buttonHeightMd,
                        minHeight: AppSpacing.buttonHeightMd,
                      ),
                      icon: const AppLineIcon(
                        AppIcons.close,
                        size: AppIconSize.leading,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ServicesSheetContent extends StatelessWidget {
  final List<String> specialties;

  const _ServicesSheetContent({required this.specialties});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < specialties.length; index++) ...[
          ConstrainedBox(
            constraints:
                const BoxConstraints(minHeight: AppSpacing.buttonHeightMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppLineIcon(
                  AppIcons.selected,
                  size: AppIconSize.action,
                  color: AppColors.primaryInk,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    specialties[index],
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (index < specialties.length - 1)
            const Divider(height: 1, color: AppColors.border),
        ],
      ],
    );
  }
}

/// Skeleton que conserva la silueta del nuevo detalle compacto.
class ServiceProviderDetailSkeleton extends StatelessWidget {
  const ServiceProviderDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          SkeletonBox(height: 252, borderRadius: 0),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: SkeletonBox(height: 356, borderRadius: 16),
          ),
        ],
      ),
    );
  }
}
