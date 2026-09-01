import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/domain/enums/offer_status.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/chat_thread.dart';
import '../../domain/entities/non_delivery_reason.dart';
import '../../../reports/presentation/providers/reports_provider.dart';
import '../providers/chat_providers.dart';
import 'decline_match_dialog.dart';
import 'non_delivery_dialog.dart';
import '_atoms/card_shell.dart';
import '_atoms/card_tokens.dart';
import '_atoms/status_badge.dart';
import '_atoms/meta_line.dart';
import '_atoms/price_text.dart';
import '_atoms/expiration_label.dart';

/// Card de solicitud de búsqueda — vista tienda.
///
/// Misma estructura de tres zonas que la card del consumidor, pero el footer
/// es una acción (cotizar / marcar entregado) en lugar de un precio, porque
/// aquí la tarea del usuario es **responder**, no comparar.
class ChatThreadCard extends ConsumerStatefulWidget {
  final ChatThread thread;
  final VoidCallback onTap;
  final VoidCallback onViewDetail;

  const ChatThreadCard({
    super.key,
    required this.thread,
    required this.onTap,
    required this.onViewDetail,
  });

  @override
  ConsumerState<ChatThreadCard> createState() => _ChatThreadCardState();
}

class _ChatThreadCardState extends ConsumerState<ChatThreadCard> {
  bool _isSubmitting = false;

  void _markDelivered() async {
    final thread = widget.thread;
    if (thread.offerId == null) return;

    setState(() => _isSubmitting = true);
    try {
      final useCase = ref.read(deliverOfferUseCaseProvider);
      final result = await useCase(thread.offerId!);

      result.fold(
        (failure) {
          if (mounted) {
            context.showSnackBar(
              'Error al marcar entrega: ${failure.message}',
              isError: true,
            );
          }
        },
        (_) {
          if (mounted) {
            ref.invalidate(storeSalesRequestsProvider);
            ref.invalidate(storeDashboardProvider);
          }
        },
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _markNotDelivered() async {
    final offerId = widget.thread.offerId;
    if (offerId == null || _isSubmitting) return;
    final selection = await NonDeliveryDialog.show(context);
    if (selection == null || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(cancelSaleByStoreUseCaseProvider)(
        offerId,
        reasonCode: selection.reasonCode,
        note: selection.note,
      );
      if (!mounted) return;
      result.fold(
        (failure) => context.showSnackBar(
          failure.code == 409
              ? 'La compra cambió de estado. Actualizamos la información.'
              : 'No se pudo cancelar el pedido: ${failure.message}',
          isError: true,
        ),
        (_) {
          ref.invalidate(storeSalesRequestsProvider);
          ref.invalidate(storeDashboardProvider);
        },
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _declineMatch() async {
    final searchMatchId = widget.thread.searchMatchId;
    if (searchMatchId == null || _isSubmitting) return;

    final reason = await DeclineMatchDialog.show(context);
    if (reason == null || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(declineMatchUseCaseProvider)(
        searchMatchId,
        reason,
      );
      if (!mounted) return;
      result.fold(
        (failure) => context.showSnackBar(
          'No se pudo declinar: ${failure.message}',
          isError: true,
        ),
        (_) {
          ref.invalidate(storeSalesRequestsProvider);
          ref.invalidate(storeDashboardProvider);
        },
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _undoDecline() async {
    final searchMatchId = widget.thread.searchMatchId;
    if (searchMatchId == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(undoDeclineUseCaseProvider)(searchMatchId);
      if (!mounted) return;
      result.fold(
        (failure) => context.showSnackBar(
          'No se pudo restaurar: ${failure.message}',
          isError: true,
        ),
        (_) {
          ref.invalidate(storeSalesRequestsProvider);
          ref.invalidate(storeDashboardProvider);
        },
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _declineReasonLabel(String? reason) {
    return DeclineMatchDialog.reasons[reason] ?? 'Motivo no especificado';
  }

  String _partTypeLabel(String raw) {
    switch (raw) {
      case 'ORIGINAL':
        return 'OEM';
      case 'GENERIC':
        return 'Genérico';
      case 'PERFORMANCE':
        return 'Alto rendimiento';
      default:
        return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;
    final expStr =
        expirationLabel(thread.expiresAt, isExpired: thread.isExpired);

    // Validaciones estrictas de estado y pertenencia
    final bool hasStoreOffer = thread.hasOffer;
    final bool isBought = hasStoreOffer && thread.offerStatus == 'BOUGHT';
    final bool isDelivered = hasStoreOffer && thread.offerStatus == 'DELIVERED';
    final bool isDiscarded = hasStoreOffer && thread.offerStatus == 'DISCARDED';
    final bool isCancelled = hasStoreOffer && thread.offerStatus == 'CANCELLED';
    final bool isDeclined = thread.matchState == 'DECLINED';
    final bool isInquiry = thread.isInquiryState;
    final bool isQuoted = thread.matchState == 'QUOTED' ||
        (thread.hasFormalQuote &&
            !isBought &&
            !isDelivered &&
            !isDiscarded &&
            !isCancelled);
    final bool canQuoteNow = (thread.matchState == 'PENDING' ||
            (thread.matchState == null && !hasStoreOffer)) &&
        thread.isOpen &&
        !thread.isExpired;
    final bool canDecline = thread.searchMatchId != null &&
        (canQuoteNow || isInquiry) &&
        thread.isOpen &&
        !thread.isExpired;
    final bool isClosedWithoutQuote =
        !hasStoreOffer && (!thread.isOpen || thread.isExpired);

    final OfferStatus status;
    String? labelOverride;

    if (isDelivered) {
      status = OfferStatus.delivered;
    } else if (isCancelled) {
      status = OfferStatus.cancelled;
    } else if (isBought) {
      status = OfferStatus.bought;
    } else if (isDiscarded) {
      status = OfferStatus.discarded;
      labelOverride = 'OTRA OFERTA ELEGIDA';
    } else if (isDeclined) {
      status = OfferStatus.unknown;
      labelOverride = 'DECLINADA';
    } else if (isInquiry) {
      status = OfferStatus.noQuoteYet;
      labelOverride = 'CONSULTA ABIERTA';
    } else if (isQuoted) {
      status = OfferStatus.sent;
    } else if (canQuoteNow) {
      status = OfferStatus.unquoted;
    } else {
      status = OfferStatus.discarded;
      labelOverride = 'SOLICITUD CERRADA';
    }

    final semanticLabel = StringBuffer(
      'Solicitud de ${thread.clientName ?? "cliente"}, ${thread.title}',
    );
    if (thread.subcategory != null) {
      semanticLabel.write(', ${thread.subcategory}');
    }
    semanticLabel.write(', ${(labelOverride ?? status.label).toLowerCase()}');
    if (thread.distance != null) {
      semanticLabel
          .write(', a ${thread.distance!.toStringAsFixed(1)} kilómetros');
    }

    return CardShell(
      onTap: widget.onTap,
      accentColor: status.accentColor,
      semanticLabel: semanticLabel.toString(),
      topRightWidget: (expStr.isNotEmpty)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    thread.isExpired ? AppColors.errorLight : AppColors.grey50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: thread.isExpired
                        ? AppColors.errorInk
                        : AppColors.textMeta,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    expStr,
                    style: CardTokens.meta.copyWith(
                      color: thread.isExpired
                          ? AppColors.errorInk
                          : AppColors.textMeta,
                      fontWeight:
                          thread.isExpired ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Zona 1: estado + expiración ──────────────────────────────────
          Row(
            children: [
              Flexible(
                child:
                    StatusBadge(status: status, labelOverride: labelOverride),
              ),
            ],
          ),
          const SizedBox(height: CardTokens.blockGap),

          // ── Zona 2: miniatura + identidad de la solicitud ────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardThumb(
                url: thread.fotoUrl,
                vehicleType: thread.vehicleType,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CardTokens.title,
                    ),
                    const SizedBox(height: CardTokens.tight),
                    MetaLine(
                      items: [
                        if (thread.subcategory != null)
                          MetaItem(thread.subcategory!),
                        if (thread.partType != null)
                          MetaItem(_partTypeLabel(thread.partType!)),
                      ],
                    ),
                    if (thread.details != null &&
                        thread.details!.isNotEmpty) ...[
                      const SizedBox(height: CardTokens.gap),
                      Text(
                        thread.details!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CardTokens.body,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: CardTokens.blockGap),

          // ── Zona 3: contexto del cliente ─────────────────────────────────
          MetaLine(
            items: [
              MetaItem(thread.clientName ?? 'Cliente',
                  icon: Icons.person_outline_rounded),
              if (thread.distance != null)
                MetaItem(
                  '${thread.distance!.toStringAsFixed(1)} km',
                  icon: Icons.near_me_outlined,
                  color: AppColors.celesteInk,
                ),
              if (!hasStoreOffer)
                MetaItem(
                  thread.totalOffersCount > 0
                      ? '${thread.totalOffersCount} cotización${thread.totalOffersCount > 1 ? 'es' : ''}'
                      : 'Sé el primero',
                  icon: Icons.storefront_outlined,
                  color:
                      thread.totalOffersCount > 0 ? null : AppColors.primaryInk,
                ),
            ],
          ),

          // ── Footer: acciones según pertenencia de oferta ─────────────────
          const CardDivider(),
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            )
          else if (canQuoteNow)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    key: const Key('view-request-detail-button'),
                    onPressed: widget.onViewDetail,
                    icon: const AppLineIcon(
                      AppIcons.services,
                      size: AppIconSize.action,
                    ),
                    label: Text('Ver detalle', style: CardTokens.button),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                if (canDecline) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton.icon(
                      onPressed: _declineMatch,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      label: Text(
                        'No puedo atenderla',
                        style: CardTokens.button,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            )
          else if (isDeclined)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Motivo: ${_declineReasonLabel(thread.declineReason)}',
                    style: CardTokens.meta.copyWith(color: AppColors.textMeta),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _undoDecline,
                    child: Text('Deshacer', style: CardTokens.button),
                  ),
                ),
              ],
            )
          else if (isInquiry)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: widget.onTap,
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: Text(
                      'Continuar consulta',
                      style: CardTokens.button,
                    ),
                  ),
                ),
                if (canDecline) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: _declineMatch,
                      child: Text(
                        'Declinar solicitud',
                        style: CardTokens.button,
                      ),
                    ),
                  ),
                ],
              ],
            )
          else if (isCancelled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    switch (thread.cancelSource) {
                      'SYSTEM' => 'Compra cancelada automáticamente',
                      'STORE' => 'Compra cancelada por la tienda',
                      'CONSUMER' => 'Compra cancelada por el comprador',
                      _ => 'La compra fue cancelada.',
                    },
                    style: CardTokens.metaStrong.copyWith(
                      color: AppColors.errorInk,
                    ),
                  ),
                  if (thread.cancelReasonCode?.trim().isNotEmpty == true)
                    Text(
                      nonDeliveryReasonLabel(thread.cancelReasonCode!),
                      style: CardTokens.meta.copyWith(
                        color: AppColors.errorInk,
                      ),
                    ),
                  if (thread.cancelReason?.trim().isNotEmpty == true)
                    Text(
                      thread.cancelReason!,
                      style: CardTokens.meta.copyWith(
                        color: AppColors.errorInk,
                      ),
                    ),
                ],
              ),
            )
          else if (isBought)
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          size: 16, color: AppColors.successInk),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '¡El cliente aceptó y compró tu oferta!',
                          style: CardTokens.metaStrong
                              .copyWith(color: AppColors.successInk),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _markDelivered,
                    icon: const Icon(Icons.local_shipping_rounded, size: 18),
                    label:
                        Text('Marcar como entregado', style: CardTokens.button),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    key: const Key('not-deliver-thread-button'),
                    onPressed: _markNotDelivered,
                    icon: const Icon(Icons.block_rounded),
                    label: Text('No lo entregaré', style: CardTokens.button),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.errorInk,
                    ),
                  ),
                ),
              ],
            )
          else if (isDelivered)
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.successInk, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Entregado con éxito',
                          style: CardTokens.metaStrong
                              .copyWith(color: AppColors.successInk),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: widget.onTap,
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Ver chat', style: CardTokens.button),
                  ),
                ),
              ],
            )
          else if (isDiscarded)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'El cliente eligió otra propuesta',
                    style: CardTokens.meta.copyWith(color: AppColors.textMeta),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: widget.onTap,
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Ver chat', style: CardTokens.button),
                  ),
                ),
              ],
            )
          else if (isClosedWithoutQuote)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Solicitud cerrada sin cotizar',
                    style: CardTokens.meta.copyWith(color: AppColors.textMeta),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: widget.onTap,
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Ver chat', style: CardTokens.button),
                  ),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TU COTIZACIÓN', style: CardTokens.overline),
                      const SizedBox(height: 2),
                      PriceText(
                        amount: thread.totalCost ?? thread.offerPrice,
                        style:
                            CardTokens.price.copyWith(color: AppColors.primary),
                        fallback: 'Enviada',
                      ),
                      if (thread.deliveryCost != null)
                        Text(
                          thread.deliveryCost == 0
                              ? 'TOTAL · DELIVERY GRATIS'
                              : 'TOTAL CON DELIVERY',
                          style: CardTokens.meta,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: widget.onTap,
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Ver chat', style: CardTokens.button),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
