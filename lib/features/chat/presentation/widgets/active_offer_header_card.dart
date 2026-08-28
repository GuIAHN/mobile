import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../shared/widgets/image_viewer_dialog.dart';
import '../../../../shared/widgets/catalog_summary_card.dart';
import '../../domain/entities/chat_conversation.dart';
import '_atoms/offer_price_breakdown.dart';
import 'store_contact_sheet.dart';

class ActiveOfferHeaderCard extends StatefulWidget {
  final ChatConversation details;
  final bool isStore;
  final VoidCallback? onBuyPressed;
  final VoidCallback? onDeliverPressed;
  final VoidCallback? onCancelPressed;
  final VoidCallback? onReviewPressed;
  final bool reviewHandledLocally;
  final bool reviewHandlingStatusLoading;
  final bool isCancelling;
  final bool isDelivering;

  const ActiveOfferHeaderCard({
    super.key,
    required this.details,
    required this.isStore,
    this.onBuyPressed,
    this.onDeliverPressed,
    this.onCancelPressed,
    this.onReviewPressed,
    this.reviewHandledLocally = false,
    this.reviewHandlingStatusLoading = false,
    this.isCancelling = false,
    this.isDelivering = false,
  });

  @override
  State<ActiveOfferHeaderCard> createState() => _ActiveOfferHeaderCardState();
}

class _ActiveOfferHeaderCardState extends State<ActiveOfferHeaderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final details = widget.details;
    final isStore = widget.isStore;
    final hasDetails = (details.requestDetails != null &&
            details.requestDetails!.isNotEmpty) ||
        (details.offerMessage != null && details.offerMessage!.isNotEmpty);

    final isBought = details.offerStatus == 'BOUGHT';
    final isDelivered = details.offerStatus == 'DELIVERED';
    final isCancelled = details.offerStatus == 'CANCELLED';
    final isDeclined = details.declinedAt != null;
    final statusLabel = isCancelled
        ? 'COMPRA CANCELADA'
        : isDelivered
            ? 'OFERTA ENTREGADA'
            : isBought
                ? 'COMPRA CONFIRMADA'
                : isDeclined
                    ? 'SOLICITUD DECLINADA'
                    : details.isInquiry
                        ? 'CONSULTA ABIERTA'
                        : 'OFERTA COTIZADA';
    final usesNeutralStatus = isDeclined || details.isInquiry;
    final canCancel = !isStore && isBought && !isDelivered && !isCancelled;
    final usesStackedSummary = MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.25;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canCancel) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: TextButton.icon(
                        onPressed:
                            widget.isCancelling ? null : widget.onCancelPressed,
                        icon: widget.isCancelling
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.errorInk,
                                ),
                              )
                            : const AppLineIcon(
                                AppIcons.cancellation,
                                size: AppIconSize.inline,
                                color: AppColors.errorInk,
                              ),
                        label: Text(
                          widget.isCancelling ? 'Cancelando…' : 'Cancelar',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: widget.isCancelling
                                ? AppColors.textDisabled
                                : AppColors.errorInk,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.errorInk,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                // Imagen, datos y precio comparten una sola línea en teléfonos
                // regulares. En pantallas estrechas o con texto ampliado, el
                // precio baja para conservar la legibilidad.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OfferPhoto(
                      imageUrl: details.sparePhotoUrl,
                      title: details.spareBrand ??
                          details.subcategoryName ??
                          'Imagen de la oferta',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isCancelled
                                        ? AppColors.errorLight
                                        : usesNeutralStatus
                                            ? AppColors.grey100
                                            : AppColors.primaryMuted,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: isCancelled
                                          ? AppColors.errorInk
                                          : usesNeutralStatus
                                              ? AppColors.grey700
                                              : AppColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              if (details.hasDelivery) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.local_shipping_rounded,
                                  size: 13,
                                  color: AppColors.success,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            details.spareBrand != null &&
                                    details.spareBrand!.isNotEmpty
                                ? details.spareBrand!
                                : (details.subcategoryName ??
                                    'Repuesto solicitado'),
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (details.vehicleTitle != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.directions_car_rounded,
                                    size: 12, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    details.vehicleTitle!,
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (!isStore && details.storeRating != null) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${details.storeRating!.toStringAsFixed(1)} (${details.storeReviewCount})',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!usesStackedSummary) ...[
                      const SizedBox(width: 10),
                      _OfferPriceSummary(
                        details: details,
                        alignment: CrossAxisAlignment.end,
                      ),
                    ],
                  ],
                ),
                if (usesStackedSummary) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _OfferPriceSummary(
                      details: details,
                      alignment: CrossAxisAlignment.end,
                    ),
                  ),
                ],

                // Seccion Acordeón: Desplegar Notas / Solicitud original
                if (hasDetails) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    borderRadius: BorderRadius.circular(14),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Row(
                        children: [
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _isExpanded
                                  ? 'Ocultar detalles de la solicitud'
                                  : 'Ver detalles y notas de la solicitud',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (details.requestDetails != null &&
                              details.requestDetails!.isNotEmpty) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2, right: 6),
                                  child: Icon(Icons.notes_rounded,
                                      size: 13, color: AppColors.textSecondary),
                                ),
                                Expanded(
                                  child: Text(
                                    'Solicitud cliente: "${details.requestDetails}"',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (details.offerMessage != null &&
                              details.offerMessage!.isNotEmpty) ...[
                            if (details.requestDetails != null &&
                                details.requestDetails!.isNotEmpty)
                              const Divider(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2, right: 6),
                                  child: Icon(Icons.storefront_outlined,
                                      size: 13, color: AppColors.primary),
                                ),
                                Expanded(
                                  child: Text(
                                    'Nota tienda: "${details.offerMessage}"',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 12,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],

                // ── Botones / Banners de Acción Contextuales ──────────────
                if (details.offerId != null) ...[
                  const SizedBox(height: 12),

                  // 1. Consumidor: Comprar Ahora (solo si ya hay precio)
                  if (!isStore &&
                      !details.isInquiry &&
                      (!isBought && !isDelivered && !isCancelled))
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: widget.onBuyPressed,
                        icon: const Icon(Icons.shopping_cart_outlined,
                            size: 18, color: Colors.white),
                        label: Text(
                          (details.totalCost ?? details.price) != null
                              ? 'Comprar Ahora • ${Formatters.currency(details.totalCost ?? details.price!)}'
                              : 'Comprar Ahora',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                      ),
                    )

                  // 2. Consumidor: Esperando entrega + Acciones Directas de Contacto
                  else if (!isStore && isBought)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color:
                                AppColors.successLight.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    AppColors.success.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  size: 16, color: AppColors.successInk),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Compra en proceso • Contacta a la tienda',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.successInk,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => StoreContactSheet.show(
                              context,
                              details: details,
                              isPostPurchase: false,
                            ),
                            icon: const AppLineIcon(
                              AppIcons.store,
                              size: AppIconSize.inline,
                              color: AppColors.primary,
                            ),
                            label: Text(
                              'Ver datos de la tienda',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )

                  // 3. Tienda: Marcar como Entregado
                  else if (isStore && isBought)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        key: const Key('deliver-offer-button'),
                        onPressed: widget.isDelivering
                            ? null
                            : widget.onDeliverPressed,
                        icon: widget.isDelivering
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                        label: Text(
                          widget.isDelivering
                              ? 'Marcando entrega…'
                              : 'Marcar como Entregado',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          disabledBackgroundColor: AppColors.success,
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                      ),
                    )

                  // 4. Entregado -> Reseñas / Calificar
                  else if (isDelivered)
                    _buildReviewSection(context, details, isStore)
                  else if (isCancelled)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.block_rounded,
                            color: AppColors.errorInk,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  details.cancelSource == 'SYSTEM'
                                      ? 'Compra cancelada automáticamente'
                                      : 'Compra cancelada',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.errorInk,
                                  ),
                                ),
                                if (details.cancelReason != null &&
                                    details.cancelReason!
                                        .trim()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    details.cancelReason!,
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 12.5,
                                      height: 1.35,
                                      color: AppColors.errorInk,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(
      BuildContext context, ChatConversation details, bool isStore) {
    if (widget.reviewHandlingStatusLoading && !isStore) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (details.hasReviewed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      isStore ? 'RESEÑA RECIBIDA' : 'TU RESEÑA ENVIADA',
                      style: GoogleFonts.hankenGrotesk(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < (details.reviewRating ?? 5)
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            if (details.reviewComment != null &&
                details.reviewComment!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '"${details.reviewComment}"',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (widget.reviewHandledLocally && !isStore) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.successLight.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.successInk, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'VALORACIÓN ENVIADA',
                style: GoogleFonts.hankenGrotesk(
                  color: AppColors.successInk,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!isStore) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: widget.onReviewPressed,
          icon: const Icon(Icons.star_outline_rounded,
              size: 18, color: Colors.amber),
          label: Text(
            'Calificar Experiencia con la Tienda',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.amber.shade900,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.amber.shade700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _OfferPhoto extends StatelessWidget {
  final String? imageUrl;
  final String title;

  const _OfferPhoto({
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = resolveMediaUrl(imageUrl);
    final hasImage = resolvedImageUrl != null;
    final content = SizedBox.square(
      dimension: 58,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.grey100,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      resolvedImageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                      errorBuilder: (_, __, ___) => const Center(
                        child: AppLineIcon(
                          AppIcons.offer,
                          size: AppIconSize.leading,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withValues(alpha: 0.76),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: AppLineIcon(
                            AppIcons.externalLink,
                            size: AppIconSize.inline,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: AppLineIcon(
                    AppIcons.offer,
                    size: AppIconSize.leading,
                    color: AppColors.primary,
                  ),
                ),
        ),
      ),
    );

    if (!hasImage) return content;

    return Semantics(
      button: true,
      label: 'Ampliar imagen de la oferta',
      hint: 'Abre la imagen a pantalla completa con zoom',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => ImageViewerDialog.show(
            context,
            resolvedImageUrl,
            title: title,
          ),
          child: content,
        ),
      ),
    );
  }
}

class _OfferPriceSummary extends StatelessWidget {
  final ChatConversation details;
  final CrossAxisAlignment alignment;

  const _OfferPriceSummary({
    required this.details,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        OfferPriceBreakdown(
          productCost: details.price,
          deliveryCost: details.deliveryCost,
          totalCost: details.totalCost,
        ),
        if (details.partType != null) ...[
          const SizedBox(height: 2),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                catalogPartTypeLabel(details.partType!),
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
