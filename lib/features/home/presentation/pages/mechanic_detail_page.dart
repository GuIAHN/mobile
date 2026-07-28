import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/domain/enums/service_type.dart';
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
                    heroTag: 'provider-avatar-$mechanicId',
                    nombre: detail.nombre,
                    tipoLabel: detail.esTaller
                        ? 'Taller Mecánico'
                        : 'Mecánico Independiente',
                    icono: detail.esTaller
                        ? Icons.warehouse_rounded
                        : Icons.build_rounded,
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

                    DetailSectionTitle(
                        title: detail.esTaller
                            ? 'Sobre el taller'
                            : 'Sobre el mecánico'),
                    const SizedBox(height: 14),
                    DetailDescriptionCard(
                      text: detail.descripcion ?? '',
                      title: detail.esTaller
                          ? 'PRESENTACIÓN DEL TALLER'
                          : 'PRESENTACIÓN DEL MECÁNICO',
                    ),
                    const SizedBox(height: 28),

                    if (hasLocation) ...[
                      const DetailSectionTitle(title: 'Ubicación'),
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
