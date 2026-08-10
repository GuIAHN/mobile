import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/image_viewer_dialog.dart';
import 'card_tokens.dart';
import '../../../../vehicles/presentation/widgets/_atoms/vehicle_type_illustration.dart';


/// Contenedor único de las cards de solicitud/oferta.
///
/// Rediseño: superficie **neutra**, sin bordes de color ni sombras teñidas.
/// Antes el estado se señalaba con un borde de 1.5px de color más una sombra
/// del mismo tono; sumado a los rellenos internos, cada card tenía 3 o 4
/// señales de color compitiendo. Ahora la superficie no comunica estado —
/// eso es trabajo exclusivo del [StatusBadge] — y la card aporta solo
/// separación del fondo mediante una sombra suave y un borde casi invisible.
class CardShell extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? accentColor;
  final Widget? topRightWidget;

  /// Resumen legible para lectores de pantalla. Si se provee, la card se
  /// anuncia como un solo botón con este texto en vez de leer cada Text hijo
  /// por separado.
  final String? semanticLabel;

  const CardShell({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(CardTokens.pad),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.accentColor,
    this.topRightWidget,
    this.semanticLabel,
  });

  @override
  State<CardShell> createState() => _CardShellState();
}

class _CardShellState extends State<CardShell> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hasAccent = widget.accentColor != null && widget.accentColor != Colors.transparent;

    final content = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(CardTokens.radius),
            border: Border.all(color: AppColors.grey100),
            boxShadow: CardTokens.shadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(CardTokens.radius),
            child: Stack(
              children: [
                if (hasAccent)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 4,
                    child: Container(color: widget.accentColor),
                  ),
                Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
                if (widget.topRightWidget != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: widget.topRightWidget!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );



    if (widget.semanticLabel == null) return content;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: ExcludeSemantics(child: content),
    );
  }
}

/// Divisor hairline que separa el cuerpo del footer (precio o CTA).
///
/// Sustituye a los recuadros que envolvían el precio y la acción: una sola
/// línea de 1px define la zona de footer sin agregar otra caja.
class CardDivider extends StatelessWidget {
  const CardDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: CardTokens.dividerGap),
      child: Divider(height: 1, thickness: 1, color: AppColors.border),
    );
  }
}

/// Miniatura de repuesto/vehículo.
///
/// Sin borde (antes tenía uno de 1px que sumaba ruido al ya presente borde de
/// la card) y con un fondo neutro que hace de placeholder mientras carga.
/// Permite ampliar la imagen al tocarla en pantalla completa.
class CardThumb extends StatelessWidget {
  final String? url;
  final double size;
  final IconData fallbackIcon;
  final String? title;
  final String? vehicleType;

  const CardThumb({
    super.key,
    required this.url,
    this.size = CardTokens.thumbSize,
    this.fallbackIcon = Icons.directions_car_rounded,
    this.title,
    this.vehicleType,
  });

  @override
  Widget build(BuildContext context) {
    final hasValidUrl = url != null && url!.isNotEmpty;

    final childWidget = ClipRRect(
      borderRadius: BorderRadius.circular(CardTokens.thumbRadius),
      child: Container(
        width: size,
        height: size,
        color: AppColors.grey50,
        child: hasValidUrl
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _fallback(),
              )
            : _fallback(),
      ),
    );

    if (!hasValidUrl) return childWidget;

    return GestureDetector(
      onTap: () => ImageViewerDialog.show(context, url!, title: title),
      child: childWidget,
    );
  }

  Widget _fallback() {
    if (vehicleType != null && vehicleType!.isNotEmpty) {
      final assetPath = VehicleTypeIllustration.getAssetPath(vehicleType!);
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(4),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(fallbackIcon, size: size * 0.36, color: AppColors.grey400),
          ),
        ),
      );
    }
    return Center(
      child: Icon(fallbackIcon, size: size * 0.36, color: AppColors.grey400),
    );
  }
}

