import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/home_providers.dart';
import '../widgets/provider_detail_widgets.dart';

class MechanicDetailPage extends ConsumerWidget {
  final String mechanicId;

  const MechanicDetailPage({super.key, required this.mechanicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (id: mechanicId, type: ServiceType.mechanic);
    final detailAsync = ref.watch(providerDetailProvider(args));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        loading: () => const DetailSkeleton(),
        error: (e, _) => DetailErrorView(
          title: 'No se pudo cargar el perfil',
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
                    heroTag: 'provider-avatar-$mechanicId',
                    nombre: detail.nombre,
                    tipoLabel: detail.esTaller
                        ? 'Taller Mecánico'
                        : 'Mecánico Independiente',
                    icono: detail.esTaller
                        ? Icons.warehouse_rounded
                        : Icons.build_rounded,
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
                      const SizedBox(height: 28),
                    ],

                    if (detail.especialidades.isNotEmpty) ...[
                      const DetailSectionTitle(title: 'Especialidades'),
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

                    if (detail.descripcion != null &&
                        detail.descripcion!.isNotEmpty) ...[
                      DetailSectionTitle(
                          title: detail.esTaller
                              ? 'Sobre el taller'
                              : 'Sobre el mecánico'),
                      const SizedBox(height: 14),
                      DetailDescriptionCard(text: detail.descripcion!),
                      const SizedBox(height: 28),
                    ],

                    if (hasContact) ...[
                      const DetailSectionTitle(title: 'Contacto'),
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
