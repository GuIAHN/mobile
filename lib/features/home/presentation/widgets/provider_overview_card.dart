import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../domain/entities/provider_detail.dart';
import 'mechanic_profile_header.dart';
import 'provider_metrics.dart';
import 'provider_introduction.dart';
import 'provider_detail_sheets.dart';

class ProviderOverviewCard extends StatelessWidget {
  final String heroTag;
  final ProviderDetail detail;
  final ServiceType serviceType;
  final double? distanceKm;

  const ProviderOverviewCard({
    super.key,
    required this.heroTag,
    required this.detail,
    required this.serviceType,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final description = detail.descripcion?.trim();
    final hasDescription = description != null && description.isNotEmpty;
    final hasLocation = (detail.direccion?.trim().isNotEmpty ?? false) ||
        detail.lat != null ||
        detail.lng != null;
    final hasPhone = detail.telefono?.trim().isNotEmpty ?? false;
    final isStore = serviceType == ServiceType.spareParts;
    final offerings = isStore
        ? detail.categorias.map((category) => category.name).toList()
        : detail.especialidades;
    final offeringsTitle = isStore ? 'Catálogo' : 'Servicios';

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
          if (serviceType == ServiceType.mechanic)
            MechanicProfileHeader(detail: detail, heroTag: heroTag)
          else
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
          ProviderMetrics(
            detail: detail,
            distanceKm: distanceKm,
            fullWidthForLargeText: serviceType == ServiceType.mechanic,
          ),
          if (hasDescription) ...[
            const SizedBox(height: AppSpacing.lg),
            ProviderIntroduction(
              description: description,
              serviceType: serviceType,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          _CompactInfoRow(
            key: const Key('service-provider-services-row'),
            icon: isStore ? AppIcons.catalog : AppIcons.services,
            title: offeringsTitle,
            value: _offeringsSummary(offerings, isStore: isStore),
            enabled: offerings.isNotEmpty,
            onTap: offerings.isEmpty
                ? null
                : () => showProviderServicesSheet(
                      context,
                      offerings,
                      title: isStore
                          ? 'Catálogo de repuestos'
                          : 'Servicios que ofrece',
                    ),
          ),
          const Divider(height: 1, color: AppColors.border),
          _CompactInfoRow(
            key: const Key('service-provider-location-row'),
            icon: AppIcons.location,
            title: 'Ubicación',
            value: _locationSummary(detail),
            enabled: hasLocation,
            onTap: hasLocation
                ? () => showProviderLocationSheet(context, detail)
                : null,
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

String _offeringsSummary(List<String> offerings, {required bool isStore}) {
  if (offerings.isEmpty) {
    return isStore ? 'Catálogo por confirmar' : 'Servicios por confirmar';
  }
  if (offerings.length == 1) return offerings.first;
  if (offerings.length == 2) return offerings.join(' · ');
  return '${offerings.take(2).join(' · ')} · +${offerings.length - 2}';
}

String _locationSummary(ProviderDetail detail) {
  final address = detail.direccion?.trim();
  if (address != null && address.isNotEmpty) return address;
  if (detail.lat != null && detail.lng != null) {
    return '${detail.lat!.toStringAsFixed(4)}, ${detail.lng!.toStringAsFixed(4)}';
  }
  return 'Ubicación por confirmar';
}
