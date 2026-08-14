import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/domain/enums/offer_status.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/chat_thread.dart';
import '_atoms/card_tokens.dart';
import '_atoms/expiration_label.dart';
import '../../../../features/vehicles/presentation/widgets/_atoms/vehicle_type_illustration.dart';
import '../../../../shared/widgets/image_viewer_dialog.dart';

/// Card de solicitud de búsqueda rediseñada — vista consumidor.
///
/// Jerarquía visual en 3 zonas diferenciadas:
///   1. Encabezado con badge de estado y temporizador de expiración.
///   2. Cuerpo: miniatura a la izquierda, título / categoría / detalles a la
///      derecha — sin competencia de colores.
///   3. Footer de acción: precio de la mejor oferta como héroe, nombre de la
///      tienda y contador de cotizaciones.
class ConsumerThreadCard extends StatefulWidget {
  final ChatThread thread;
  final VoidCallback onTap;

  const ConsumerThreadCard({
    super.key,
    required this.thread,
    required this.onTap,
  });

  @override
  State<ConsumerThreadCard> createState() => _ConsumerThreadCardState();
}

class _ConsumerThreadCardState extends State<ConsumerThreadCard> {
  bool _isPressed = false;

  ({OfferStatus status, String? labelOverride}) _resolveStatus() {
    final t = widget.thread;
    if (t.bestOfferStatus == 'BOUGHT') {
      return (status: OfferStatus.bought, labelOverride: 'COMPRADA');
    }
    if (t.bestOfferStatus == 'DELIVERED') {
      return (status: OfferStatus.delivered, labelOverride: null);
    }
    if (!t.isOpen || t.isExpired) {
      return (status: OfferStatus.discarded, labelOverride: 'CERRADA');
    }
    final hasOffers = t.totalOffersCount > 0 || t.bestOfferPrice != null;
    if (hasOffers) {
      return (status: OfferStatus.offersReceived, labelOverride: null);
    }
    return (status: OfferStatus.noOffers, labelOverride: null);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.thread;
    final expStr = expirationLabel(t.expiresAt, isExpired: t.isExpired);
    final resolved = _resolveStatus();
    final status = resolved.status;
    final isClosed = status == OfferStatus.discarded ||
        status == OfferStatus.bought ||
        status == OfferStatus.delivered;
    final hasBestOffer = t.bestOfferPrice != null;
    final hasOffers = t.totalOffersCount > 0 || hasBestOffer;
    final isSearching = status == OfferStatus.noOffers;

    return Semantics(
      button: true,
      label: _semanticLabel(resolved, hasBestOffer, expStr, isClosed),
      child: ExcludeSemantics(
        child: GestureDetector(
          onTapDown: (_) {
            setState(() => _isPressed = true);
            HapticFeedback.selectionClick();
          },
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.982 : 1.0,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(CardTokens.radius),
                border: Border.all(color: AppColors.grey100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(CardTokens.radius),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Franja lateral de acento (estado) ──────────────────
                    _AccentStripe(status: status),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Zona 1: estado + temporizador ────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _StatusPill(
                                status: status,
                                label: resolved.labelOverride,
                              ),
                              const Spacer(),
                              if (!isClosed && expStr.isNotEmpty)
                                _ExpirationChip(label: expStr),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // ── Zona 2: miniatura + identidad ────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ThreadThumbnail(
                                url: t.fotoUrl,
                                vehicleType: t.vehicleType,
                                isActive: !isClosed,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: CardTokens.title,
                                    ),
                                    if (t.subcategory != null) ...[
                                      const SizedBox(height: 4),
                                      _CategoryRow(
                                        subcategory: t.subcategory!,
                                        partType: t.partType,
                                      ),
                                    ],
                                    if (t.details != null &&
                                        t.details!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        t.details!,
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
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),

                    // ── Zona 3: footer de oferta ──────────────────────────
                    _OfferFooter(
                      hasBestOffer: hasBestOffer,
                      hasOffers: hasOffers,
                      isSearching: isSearching,
                      isClosed: isClosed,
                      bestOfferPrice: t.bestOfferPrice,
                      bestOfferStoreName: t.bestOfferStoreName,
                      totalOffersCount: t.totalOffersCount,
                      status: status,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _semanticLabel(
    ({OfferStatus status, String? labelOverride}) resolved,
    bool hasBestOffer,
    String expStr,
    bool isClosed,
  ) {
    final t = widget.thread;
    final buf = StringBuffer('Solicitud ${t.title}');
    if (t.subcategory != null) buf.write(', ${t.subcategory}');
    buf.write(
        ', ${(resolved.labelOverride ?? resolved.status.label).toLowerCase()}');
    if (hasBestOffer) {
      buf.write(
          ', mejor oferta ${t.bestOfferPrice!.toStringAsFixed(0)} lempiras');
    }
    if (!isClosed && expStr.isNotEmpty) buf.write(', $expStr');
    return buf.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Átomos privados
// ─────────────────────────────────────────────────────────────────────────────

/// Franja fina superior que actúa como acento de estado sin invadir el cuerpo.
class _AccentStripe extends StatelessWidget {
  final OfferStatus status;

  const _AccentStripe({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.accentColor;
    if (color == Colors.transparent) return const SizedBox.shrink();
    return Container(height: 3, color: color);
  }
}

/// Pill de estado con ícono — el único elemento relleno del cuerpo de la card.
class _StatusPill extends StatelessWidget {
  final OfferStatus status;
  final String? label;

  const _StatusPill({required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: status.foreground),
          const SizedBox(width: 5),
          Text(
            label ?? status.label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: status.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de expiración sutil, sin relleno competidor.
class _ExpirationChip extends StatelessWidget {
  final String label;

  const _ExpirationChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textMeta),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textMeta,
          ),
        ),
      ],
    );
  }
}

/// Miniatura cuadrada con indicador de actividad pulsante.
class _ThreadThumbnail extends StatelessWidget {
  final String? url;
  final String? vehicleType;
  final bool isActive;

  const _ThreadThumbnail({
    this.url,
    this.vehicleType,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    const size = CardTokens.thumbSize;
    final hasUrl = url != null && url!.isNotEmpty;

    Widget thumb = ClipRRect(
      borderRadius: BorderRadius.circular(CardTokens.thumbRadius),
      child: Container(
        width: size,
        height: size,
        color: AppColors.grey50,
        child: hasUrl
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(size),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _fallback(size),
              )
            : _fallback(size),
      ),
    );

    if (hasUrl) {
      thumb = GestureDetector(
        onTap: () => ImageViewerDialog.show(context, url!),
        child: thumb,
      );
    }

    return thumb;
  }

  Widget _fallback(double size) {
    if (vehicleType != null && vehicleType!.isNotEmpty) {
      final path = VehicleTypeIllustration.getAssetPath(vehicleType!);
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          path,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(Icons.directions_car_rounded,
                size: size * 0.36, color: AppColors.grey400),
          ),
        ),
      );
    }
    return Center(
      child: Icon(Icons.directions_car_rounded,
          size: size * 0.36, color: AppColors.grey400),
    );
  }
}

/// Fila de categoría + tipo de parte, como chips de texto ligero.
class _CategoryRow extends StatelessWidget {
  final String subcategory;
  final String? partType;

  const _CategoryRow({required this.subcategory, this.partType});

  String _partLabel(String raw) {
    switch (raw) {
      case 'ORIGINAL':
        return 'Original';
      case 'GENERIC':
        return 'Genérico';
      case 'PERFORMANCE':
        return 'Performance';
      default:
        return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _Tag(label: subcategory, icon: Icons.category_outlined),
        if (partType != null)
          _Tag(label: _partLabel(partType!), icon: Icons.build_outlined),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Tag({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMeta),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textMeta,
          ),
        ),
      ],
    );
  }
}

/// Footer de oferta: precio héroe a la izquierda, detalles + CTA a la derecha.
class _OfferFooter extends StatelessWidget {
  final bool hasBestOffer;
  final bool hasOffers;
  final bool isSearching;
  final bool isClosed;
  final double? bestOfferPrice;
  final String? bestOfferStoreName;
  final int totalOffersCount;
  final OfferStatus status;

  const _OfferFooter({
    required this.hasBestOffer,
    required this.hasOffers,
    required this.isSearching,
    required this.isClosed,
    required this.bestOfferPrice,
    required this.bestOfferStoreName,
    required this.totalOffersCount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final Color footerBg = hasBestOffer
        ? AppColors.primaryMuted.withValues(alpha: 0.45)
        : isSearching
            ? AppColors.warningLight.withValues(alpha: 0.3)
            : AppColors.grey50;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: footerBg,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Precio héroe
          Expanded(
            child: hasBestOffer
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MEJOR OFERTA',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: AppColors.primaryInk.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.currency(bestOfferPrice!),
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.1,
                          color: AppColors.primaryInk,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (bestOfferStoreName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          bestOfferStoreName!,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryInk.withValues(alpha: 0.65),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSearching ? 'SIN COTIZACIONES AÚN' : 'ESTADO',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: AppColors.textMeta,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isSearching
                            ? 'Esperando respuesta'
                            : isClosed
                                ? 'Solicitud finalizada'
                                : 'Ver detalles',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),

          // Contador de ofertas + flecha
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (totalOffersCount > 0)
                _OfferCountBadge(count: totalOffersCount, hasOffer: hasBestOffer),
              const SizedBox(height: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: hasBestOffer ? AppColors.primaryInk : AppColors.grey400,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Burbuja con el número de cotizaciones recibidas.
class _OfferCountBadge extends StatelessWidget {
  final int count;
  final bool hasOffer;

  const _OfferCountBadge({required this.count, required this.hasOffer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: hasOffer ? AppColors.primary : AppColors.grey200,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$count ${count == 1 ? 'cotización' : 'cotizaciones'}',
        style: GoogleFonts.hankenGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: hasOffer ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}
