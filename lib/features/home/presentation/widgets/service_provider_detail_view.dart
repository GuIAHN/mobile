import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/provider_feedback/provider_feedback_scope.dart';
import '../../domain/entities/provider_detail.dart';
import '../providers/home_providers.dart';
import 'provider_detail_header.dart';
import 'provider_detail_widgets.dart';
import 'provider_overview_card.dart';
import 'provider_contact_bar.dart';

/// Detalle compacto para mecánicos y talleres.
///
/// Mantiene la información esencial en una sola ficha y desplaza el mapa y el
/// contenido largo a sheets bajo demanda. Las acciones de contacto permanecen
/// visibles sin ocupar espacio dentro del scroll.
class ServiceProviderDetailView extends ConsumerWidget {
  final ProviderDetail detail;
  final String heroTag;
  final ServiceType serviceType;
  final String? reviewOfferId;
  final double? distanceKm;

  const ServiceProviderDetailView({
    super.key,
    required this.detail,
    required this.heroTag,
    this.serviceType = ServiceType.mechanic,
    this.reviewOfferId,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = detail.telefono?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;
    final selectedVehicle = ref.watch(searchVehicleProvider);
    final isStore = serviceType == ServiceType.spareParts;
    final feedback = ProviderFeedbackScope.of(context);
    final reviewTarget = detail.userId == null
        ? null
        : ProviderFeedbackTarget(
            userId: detail.userId!,
            profileId: detail.id,
            name: detail.nombre,
            offerId: reviewOfferId,
          );

    Future<void> contact(String channel) async {
      HapticFeedback.lightImpact();
      if (!isStore) {
        await feedback.registerContact(detail.id, channel);
      }
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
              ProviderDetailHeader(
                  detail: detail, heroTag: heroTag, serviceType: serviceType),
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
                      ProviderOverviewCard(
                        heroTag: heroTag,
                        detail: detail,
                        serviceType: serviceType,
                        distanceKm: distanceKm,
                      ),
                      if (reviewTarget != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        feedback.buildReviewsButton(reviewTarget),
                        if (!isStore ||
                            reviewOfferId?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: AppSpacing.md),
                          feedback.buildReviewAction(reviewTarget),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasPhone)
          ProviderContactBar(
            phone: phone,
            onCall: () => contact('PHONE'),
            onWhatsApp: () => contact('WHATSAPP'),
          ),
      ],
    );
  }
}
