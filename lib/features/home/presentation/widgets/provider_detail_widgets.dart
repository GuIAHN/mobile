import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/skeleton_loader.dart';

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

  const DetailHeaderBackground({
    super.key,
    required this.heroTag,
    required this.nombre,
    required this.tipoLabel,
    required this.icono,
    this.verified = false,
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
                  child: Icon(icono, size: 38, color: Colors.white),
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

/// Botón back circular para usar como leading del SliverAppBar.
class DetailBackButton extends StatelessWidget {
  const DetailBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Semantics(
        button: true,
        label: 'Volver',
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: AppColors.textPrimary,
            tooltip: 'Volver',
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}

// ── Stats ─────────────────────────────────────────────────────────────────

class DetailStat {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const DetailStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
}

/// Card flotante de métricas. Solo renderiza stats con valor real
/// (nada de "N/D" que ensucia la jerarquía visual).
class DetailStatsCard extends StatelessWidget {
  final List<DetailStat> stats;

  const DetailStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (var i = 0; i < stats.length; i++) {
      if (i > 0) {
        children.add(Container(
          width: 1,
          height: 40,
          color: AppColors.grey200,
          margin: const EdgeInsets.symmetric(horizontal: 8),
        ));
      }
      children.add(Expanded(child: _StatItem(stat: stats[i])));
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(children: children),
    );
  }
}

class _StatItem extends StatelessWidget {
  final DetailStat stat;

  const _StatItem({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: stat.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(stat.icon, color: stat.color, size: 18),
        ),
        const SizedBox(height: 7),
        Text(
          stat.value,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          stat.label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 10.5,
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

/// Card blanca de texto largo (descripción).
class DetailDescriptionCard extends StatelessWidget {
  final String text;

  const DetailDescriptionCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
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
      child: Text(
        text,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 14,
          height: 1.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Contacto accionable ───────────────────────────────────────────────────

/// Tile de contacto que SÍ hace algo: llama, abre correo o copia.
/// Feedback de presión + Semantics de botón.
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

/// Acciones de contacto: teléfono y correo con url_launcher,
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

  static Future<void> email(BuildContext context, String address) async {
    final uri = Uri(scheme: 'mailto', path: address);
    if (!await launchUrl(uri)) {
      if (!context.mounted) return;
      await _copyFallback(context, address, 'Correo copiado al portapapeles');
    }
  }

  static Future<void> _copyFallback(
    BuildContext context,
    String value,
    String message,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── CTA ───────────────────────────────────────────────────────────────────

/// Bottom sheet de contacto rápido (estilo GuIA: radius 28 + handle).
class ContactSheet extends StatelessWidget {
  final String nombre;
  final String? telefono;
  final String? email;

  const ContactSheet({
    super.key,
    required this.nombre,
    this.telefono,
    this.email,
  });

  static Future<void> show(
    BuildContext context, {
    required String nombre,
    String? telefono,
    String? email,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => ContactSheet(
        nombre: nombre,
        telefono: telefono,
        email: email,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Contactar a $nombre',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            if (telefono != null)
              _SheetAction(
                icon: Icons.phone_rounded,
                color: AppColors.success,
                label: 'Llamar',
                sublabel: telefono!,
                onTap: () {
                  Navigator.pop(context);
                  ContactActions.call(context, telefono!);
                },
              ),
            if (email != null)
              _SheetAction(
                icon: Icons.email_rounded,
                color: AppColors.tertiary,
                label: 'Enviar correo',
                sublabel: email!,
                onTap: () {
                  Navigator.pop(context);
                  ContactActions.email(context, email!);
                },
              ),
            if (telefono != null)
              _SheetAction(
                icon: Icons.copy_rounded,
                color: AppColors.primary,
                label: 'Copiar teléfono',
                sublabel: telefono!,
                onTap: () async {
                  Navigator.pop(context);
                  await Clipboard.setData(ClipboardData(text: telefono!));
                  HapticFeedback.mediumImpact();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 21, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      sublabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}

/// CTA principal pill con sombra de marca (según DESIGN_SYSTEM.md).
class DetailCtaButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const DetailCtaButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onPressed!();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFD9DCE1),
          disabledForegroundColor: const Color(0xFF9AA0A8),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 18),
          ],
        ),
      ),
    );
  }
}

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
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 34, color: AppColors.error),
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
                icon: const Icon(Icons.refresh_rounded, size: 18),
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
