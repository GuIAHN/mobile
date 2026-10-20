import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:flutter/services.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../domain/entities/provider_detail.dart';
import 'provider_detail_widgets.dart';
import 'provider_photo.dart';

/// Cabecera y comportamiento de desplazamiento del detalle de proveedor.
class ProviderDetailHeader extends StatelessWidget {
  final ProviderDetail detail;
  final String heroTag;
  final ServiceType serviceType;

  const ProviderDetailHeader(
      {super.key,
      required this.detail,
      required this.heroTag,
      required this.serviceType});

  @override
  Widget build(BuildContext context) {
    final compactHero = MediaQuery.sizeOf(context).height < 760;
    final isMechanic = serviceType == ServiceType.mechanic;
    return SliverAppBar(
      expandedHeight: isMechanic ? kToolbarHeight : (compactHero ? 228 : 252),
      pinned: true,
      stretch: !isMechanic,
      backgroundColor: isMechanic ? AppColors.background : AppColors.primary,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      systemOverlayStyle:
          isMechanic ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      leadingWidth: 64,
      leading: isMechanic
          ? IconButton(
              tooltip: 'Volver',
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              onPressed: () => Navigator.pop(context),
              icon: const AppLineIcon(
                AppIcons.back,
                color: AppColors.textPrimary,
              ),
            )
          : const DetailBackButton(),
      flexibleSpace: isMechanic
          ? const ColoredBox(
              key: Key('service-provider-hero'),
              color: AppColors.background,
            )
          : FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              stretchModes: const [StretchMode.zoomBackground],
              background: _ProviderHero(
                detail: detail,
                heroTag: heroTag,
                serviceType: serviceType,
              ),
            ),
    );
  }
}

class _ProviderHero extends StatelessWidget {
  final ProviderDetail detail;
  final String heroTag;
  final ServiceType serviceType;

  const _ProviderHero({
    required this.detail,
    required this.heroTag,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    final photo = detail.photo?.trim();
    final image = Hero(
      tag: heroTag,
      child: ProviderPhoto(
        photoUrl: photo,
        providerName: detail.nombre,
        networkKey: const Key('service-provider-hero-photo'),
        loadingFallback: _HeroFallback(
          icon: _providerIcon(serviceType),
          showProgress: true,
        ),
        fallback: _HeroFallback(
          key: const Key('service-provider-hero-fallback'),
          icon: _providerIcon(serviceType),
        ),
      ),
    );

    return Stack(
      key: const Key('service-provider-hero'),
      fit: StackFit.expand,
      children: [
        image,
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
          child: _ProviderTypeBadge(serviceType: serviceType),
        ),
      ],
    );
  }
}

class _ProviderTypeBadge extends StatelessWidget {
  final ServiceType serviceType;

  const _ProviderTypeBadge({required this.serviceType});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            _providerIcon(serviceType),
            size: AppIconSize.inline,
            color: AppColors.primaryInk,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _providerTypeLabel(serviceType),
            style: AppTypography.label.copyWith(
              color: serviceType == ServiceType.mechanic
                  ? AppColors.textPrimary
                  : AppColors.primaryInk,
            ),
          ),
        ],
      ),
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

IconData _providerIcon(ServiceType serviceType) => switch (serviceType) {
      ServiceType.spareParts => AppIcons.store,
      ServiceType.workshops || ServiceType.storeDashboard => AppIcons.workshop,
      ServiceType.mechanic => AppIcons.mechanic,
    };

String _providerTypeLabel(ServiceType serviceType) => switch (serviceType) {
      ServiceType.spareParts => 'Tienda de repuestos',
      ServiceType.workshops || ServiceType.storeDashboard => 'Taller mecánico',
      ServiceType.mechanic => 'Mecánico',
    };
