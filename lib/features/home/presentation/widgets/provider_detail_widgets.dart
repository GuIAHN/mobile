import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/guia_map.dart';
import '../../../../core/domain/entities/user_car.dart';

/// Widgets compartidos por las pantallas de detalle de proveedor
/// (mecánico, taller y tienda). Mantienen el sistema de diseño GuIA:
/// fondo #F5F6FA, cards blancas radius 20-24, naranja #F25C05, Hanken Grotesk.

// ── Header ────────────────────────────────────────────────────────────────

/// Fondo del SliverAppBar: gradiente de marca con círculos decorativos,
/// avatar con Hero (continuidad espacial desde la card del listado),
/// nombre + badge de verificado y tipo de proveedor.
class DetailHeaderBackground extends StatelessWidget {
  final String heroTag;
  final String nombre;
  final String tipoLabel;
  final IconData icono;
  final bool verified;
  final String? photoUrl;

  const DetailHeaderBackground({
    super.key,
    required this.heroTag,
    required this.nombre,
    required this.tipoLabel,
    required this.icono,
    this.verified = false,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Círculos decorativos sutiles (profundidad sin ruido)
          const Positioned(
            top: -60,
            right: -40,
            child: _DecorCircle(size: 190, opacity: 0.10),
          ),
          const Positioned(
            bottom: -30,
            left: -50,
            child: _DecorCircle(size: 150, opacity: 0.08),
          ),
          const Positioned(
            top: 70,
            left: 40,
            child: _DecorCircle(size: 46, opacity: 0.12),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 46),
              Hero(
                tag: heroTag,
                child: Container(
                  width: 84,
                  height: 84,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.65),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: photoUrl != null && photoUrl!.isNotEmpty
                      ? Image.network(
                          photoUrl!,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(icono, size: 38, color: Colors.white),
                        )
                      : Icon(icono, size: 38, color: Colors.white),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 56),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded,
                          size: 20, color: Colors.white),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Pill de tipo de proveedor (glass sutil)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  tipoLabel.toUpperCase(),
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _DecorCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

/// Botón back lineal para usar como leading del SliverAppBar.
class DetailBackButton extends StatelessWidget {
  const DetailBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Semantics(
        button: true,
        label: 'Volver',
        child: IconButton(
          icon: const AppLineIcon(
            AppIcons.back,
            size: AppIconSize.leading,
          ),
          color: Colors.white,
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}

// ── Hero Stats Card (Métricas Clave Unificadas) ───────────────────────────

/// Card única y unificada de métricas clave (Rating, Distancia, Tarifa).
/// Elimina cualquier duplicación y mantiene una jerarquía limpia y seria.
class DetailHeroStatsCard extends StatelessWidget {
  final double? rating;
  final int ratingCount;
  final double? distanciaKm;
  final double? tarifa;

  const DetailHeroStatsCard({
    super.key,
    this.rating,
    this.ratingCount = 0,
    this.distanciaKm,
    this.tarifa,
  });

  @override
  Widget build(BuildContext context) {
    final hasRating = rating != null && rating! > 0 && ratingCount > 0;
    final ratingValue = hasRating ? rating!.toStringAsFixed(1) : 'Nuevo';
    final ratingSub = hasRating
        ? '$ratingCount ${ratingCount == 1 ? "reseña" : "reseñas"}'
        : 'Sin opiniones';

    final distanceValue = distanciaKm != null
        ? '${distanciaKm!.toStringAsFixed(1)} km'
        : 'Cercano';

    final rateValue = tarifa != null && tarifa! > 0
        ? Formatters.currencyCompact(tarifa!)
        : 'Consultar';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Stat 1: Rating (ÚNICO LUGAR DONDE SE MUESTRA EL RATING)
          Expanded(
            child: _HeroStatItem(
              icon: Icons.star_rounded,
              iconColor:
                  hasRating ? const Color(0xFFF59E0B) : AppColors.grey400,
              value: ratingValue,
              label: ratingSub,
            ),
          ),

          // Divisor vertical
          Container(
            width: 1,
            height: 38,
            color: AppColors.border,
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),

          // Stat 2: Distancia
          Expanded(
            child: _HeroStatItem(
              icon: Icons.near_me_rounded,
              iconColor: AppColors.primary,
              value: distanceValue,
              label: 'Distancia',
            ),
          ),

          // Divisor vertical
          Container(
            width: 1,
            height: 38,
            color: AppColors.border,
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),

          // Stat 3: Tarifa por hora / Rango
          Expanded(
            child: _HeroStatItem(
              icon: Icons.payments_rounded,
              iconColor: AppColors.success,
              value: rateValue,
              label: tarifa != null && tarifa! > 0 ? 'Tarifa / h' : 'Precios',
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _HeroStatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Secciones ─────────────────────────────────────────────────────────────

/// Título de sección con barra de acento naranja (jerarquía clara).
class DetailSectionTitle extends StatelessWidget {
  final String title;

  const DetailSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Chip de especialidad o servicio.
class DetailChip extends StatelessWidget {
  final String label;

  const DetailChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryMuted,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Card elegante para "Sobre el Mecánico / Taller" con icono de comillas y jerarquía visual.
class DetailDescriptionCard extends StatelessWidget {
  final String text;
  final String? title;

  const DetailDescriptionCard({
    super.key,
    required this.text,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = text.trim().isNotEmpty
        ? text.trim()
        : 'Profesional dedicado a brindar servicios automotrices de alta calidad, garantizando un trabajo seguro y confiable.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.format_quote_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title ?? 'PRESENTACIÓN Y EXPERIENCIA',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            displayText,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14.5,
              height: 1.6,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contacto accionable ───────────────────────────────────────────────────

/// Tile de contacto que SÍ hace algo: llama, abre WhatsApp o copia.
class DetailContactTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;
  final String semanticsHint;

  const DetailContactTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    required this.semanticsHint,
  });

  @override
  State<DetailContactTile> createState() => _DetailContactTileState();
}

class _DetailContactTileState extends State<DetailContactTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.label}: ${widget.value}',
      hint: widget.semanticsHint,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(widget.icon, size: 20, color: widget.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label.toUpperCase(),
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.grey50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_outward_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Acciones de contacto: llamada, WhatsApp y apertura de mapas con url_launcher,
/// con copia al portapapeles como fallback si no hay app disponible.
abstract class ContactActions {
  ContactActions._();

  static Future<void> call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      if (!context.mounted) return;
      await _copyFallback(context, phone, 'Teléfono copiado al portapapeles');
    }
  }

  static String providerInquiryMessage({UserCar? vehicle}) {
    if (vehicle == null) {
      return 'Hola, te contacto desde GuIA-HN';
    }

    final version = vehicle.version?.trim();
    return 'Hola, te contacto desde GuIA-HN. Quisiera consultar por servicios '
        'para este vehículo:\n'
        'Marca: ${vehicle.brand}\n'
        'Modelo: ${vehicle.model}\n'
        'Año: ${vehicle.year}\n'
        'Versión: ${version == null || version.isEmpty ? 'No especificada' : version}';
  }

  static Uri whatsappUri(
    String phone, {
    String? message,
  }) {
    String cleanDigits = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.length == 12 && cleanDigits.startsWith('1')) {
      cleanDigits = '58${cleanDigits.substring(2)}';
    } else if (cleanDigits.length == 11 && cleanDigits.startsWith('0')) {
      cleanDigits = '58${cleanDigits.substring(1)}';
    } else if (cleanDigits.length == 10 && cleanDigits.startsWith('4')) {
      cleanDigits = '58$cleanDigits';
    } else if (cleanDigits.length == 8) {
      cleanDigits = '504$cleanDigits';
    }
    return Uri.https(
      'wa.me',
      '/$cleanDigits',
      {'text': message ?? providerInquiryMessage()},
    );
  }

  static Future<void> whatsapp(
    BuildContext context,
    String phone, {
    String? message,
  }) async {
    final whatsappUrl = whatsappUri(phone, message: message);

    if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      await _copyFallback(
          context, phone, 'Número de WhatsApp copiado al portapapeles');
    }
  }

  static Future<void> openGoogleMaps(
    BuildContext context, {
    double? lat,
    double? lng,
    String? address,
  }) async {
    Uri mapsUri;
    if (lat != null && lng != null) {
      mapsUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else if (address != null && address.isNotEmpty) {
      mapsUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    } else {
      context.showSnackBar('Ubicación no disponible');
      return;
    }

    if (!await launchUrl(mapsUri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      await _copyFallback(
        context,
        address ?? '$lat, $lng',
        'Ubicación copiada al portapapeles',
      );
    }
  }

  static Future<void> _copyFallback(
    BuildContext context,
    String value,
    String message,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    context.showSnackBar(
      message,
      isSuccess: true,
      duration: const Duration(seconds: 2),
    );
  }
}

// ── Card de Ubicación y Mapa ──────────────────────────────────────────────

/// Card de ubicación con Google Maps y botón para abrir la navegación externa.
class DetailLocationCard extends StatelessWidget {
  final String? direccion;
  final double? lat;
  final double? lng;
  final bool embedded;

  const DetailLocationCard({
    super.key,
    this.direccion,
    this.lat,
    this.lng,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (direccion == null && lat == null && lng == null) {
      return const SizedBox.shrink();
    }

    final hasCoordinates = lat != null && lng != null;
    final point =
        hasCoordinates ? LatLng(lat!, lng!) : const LatLng(10.4806, -66.9036);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (direccion != null && direccion!.isNotEmpty) ...[
          Row(
            children: [
              const AppLineIcon(
                AppIcons.location,
                size: AppIconSize.action,
                color: AppColors.primaryInk,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  direccion!,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],

        // Google Maps compartido por todas las superficies de ubicación.
        GuiaMap(
          point: point,
          isApproximate: !hasCoordinates,
        ),
        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => ContactActions.openGoogleMaps(
              context,
              lat: lat,
              lng: lng,
              address: direccion,
            ),
            icon: const AppLineIcon(
              AppIcons.externalLink,
              size: AppIconSize.action,
            ),
            label: Text(
              'ABRIR EN GOOGLE MAPS',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
        ),
      ],
    );

    if (embedded) return content;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: content,
    );
  }
}

// ── CTA ───────────────────────────────────────────────────────────────────

// ── Estados de carga y error ──────────────────────────────────────────────

/// Skeleton con shimmer para las pantallas de detalle
/// (reemplaza los bloques grises estáticos).
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(height: 240, borderRadius: 0),
        Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(height: 86, borderRadius: 20),
              SizedBox(height: 28),
              SkeletonBox(width: 130, height: 12, borderRadius: 6),
              SizedBox(height: 14),
              Row(
                children: [
                  SkeletonBox(width: 90, height: 32, borderRadius: 99),
                  SizedBox(width: 8),
                  SkeletonBox(width: 110, height: 32, borderRadius: 99),
                  SizedBox(width: 8),
                  SkeletonBox(width: 70, height: 32, borderRadius: 99),
                ],
              ),
              SizedBox(height: 28),
              SkeletonBox(width: 130, height: 12, borderRadius: 6),
              SizedBox(height: 14),
              SkeletonBox(height: 76, borderRadius: 20),
              SizedBox(height: 12),
              SkeletonBox(height: 76, borderRadius: 20),
            ],
          ),
        ),
      ],
    );
  }
}

/// Vista de error con acción de reintento (recuperación clara, no callejón
/// sin salida).
class DetailErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const DetailErrorView({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLineIcon(
              AppIcons.connectivityError,
              size: AppIconSize.feature,
              color: AppColors.error,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const AppLineIcon(
                  AppIcons.retry,
                  size: AppIconSize.action,
                ),
                label: Text(
                  'Reintentar',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
