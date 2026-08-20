import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/chat_conversation.dart';
import 'store_contact_sheet.dart';

class ActiveOfferHeaderCard extends StatefulWidget {
  final ChatConversation details;
  final bool isStore;
  final VoidCallback? onBuyPressed;
  final VoidCallback? onDeliverPressed;
  final VoidCallback? onReviewPressed;
  final VoidCallback? onViewStoreReviewsPressed;
  final bool reviewHandledLocally;
  final bool reviewHandlingStatusLoading;

  const ActiveOfferHeaderCard({
    super.key,
    required this.details,
    required this.isStore,
    this.onBuyPressed,
    this.onDeliverPressed,
    this.onReviewPressed,
    this.onViewStoreReviewsPressed,
    this.reviewHandledLocally = false,
    this.reviewHandlingStatusLoading = false,
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                // Fila 1: Imagen del repuesto + Info Principal + Precio
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Foto del repuesto o icono genérico
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: details.sparePhotoUrl != null &&
                              details.sparePhotoUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.network(
                                details.sparePhotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.directions_car_rounded,
                                  color: AppColors.textSecondary,
                                  size: 26,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.build_circle_outlined,
                              color: AppColors.primary,
                              size: 28,
                            ),
                    ),
                    const SizedBox(width: 12),

                    // Título, Vehículo y Subcategoría
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryMuted,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'OFERTA COTIZADA',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    letterSpacing: 0.5,
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Precio destacado
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          details.price != null
                              ? Formatters.currency(details.price!)
                              : 'A convenir',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        if (details.partType != null) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              details.partType!.toUpperCase(),
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Seccion Acordeón: Desplegar Notas / Solicitud original
                if (hasDetails) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
                          Text(
                            _isExpanded
                                ? 'Ocultar detalles de la solicitud'
                                : 'Ver detalles y notas de la solicitud',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
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
                      (!isBought && !isDelivered))
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: widget.onBuyPressed,
                        icon: const Icon(Icons.shopping_cart_outlined,
                            size: 18, color: Colors.white),
                        label: Text(
                          details.price != null
                              ? 'Comprar Ahora • ${Formatters.currency(details.price!)}'
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
                            borderRadius: BorderRadius.circular(10),
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  size: 16, color: AppColors.success),
                              const SizedBox(width: 6),
                              Text(
                                'Compra en proceso • Contacta a la tienda',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => StoreContactSheet.show(
                            context,
                            details: details,
                            isPostPurchase: false,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    size: 15, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  'Ver Datos de la Tienda',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )

                  // 3. Tienda: Marcar como Entregado
                  else if (isStore && isBought)
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: widget.onDeliverPressed,
                        icon: const Icon(Icons.check_circle_outline_rounded,
                            size: 18, color: Colors.white),
                        label: Text(
                          'Marcar como Entregado',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    )

                  // 4. Entregado -> Reseñas / Calificar
                  else if (isDelivered)
                    _buildReviewSection(context, details, isStore),
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
        height: 40,
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
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
