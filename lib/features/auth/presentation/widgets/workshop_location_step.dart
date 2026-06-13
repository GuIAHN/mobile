import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class WorkshopLocationStep extends StatefulWidget {
  final Offset posicionPin;
  final ValueChanged<Offset> onPinChanged;
  final bool ubicacionConfirmada;
  final ValueChanged<bool> onUbicacionConfirmadaChanged;
  final String searchHint;
  final String helperText;

  const WorkshopLocationStep({
    super.key,
    required this.posicionPin,
    required this.onPinChanged,
    required this.ubicacionConfirmada,
    required this.onUbicacionConfirmadaChanged,
    this.searchHint = 'Buscar dirección del taller...',
    this.helperText = 'Toca el mapa para ajustar la ubicación exacta del taller',
  });

  @override
  State<WorkshopLocationStep> createState() => _WorkshopLocationStepState();
}

class _WorkshopLocationStepState extends State<WorkshopLocationStep> {
  final _searchController = TextEditingController();
  final GlobalKey _mapKey = GlobalKey();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Buscador
        TextField(
          controller: _searchController,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.searchHint,
            hintStyle: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              color: AppColors.textDisabled,
            ),
            prefixIcon: const Icon(
              Icons.search,
              size: 20,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Mapa interactivo placeholder
        GestureDetector(
          key: _mapKey,
          onTapDown: (d) {
            final renderBox = _mapKey.currentContext?.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final size = renderBox.size;
              final newPin = Offset(
                d.localPosition.dx / size.width,
                d.localPosition.dy / size.height,
              );
              widget.onPinChanged(newPin);
              widget.onUbicacionConfirmadaChanged(false);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 300.0,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _MapaPainter()),
                  ),
                  Positioned.fill(
                    child: TweenAnimationBuilder<Offset>(
                      tween: Tween<Offset>(end: widget.posicionPin),
                      duration: const Duration(milliseconds: 250),
                      builder: (context, pos, child) {
                        return CustomSingleChildLayout(
                          delegate: _PinLayoutDelegate(pos),
                          child: child,
                        );
                      },
                      child: const Icon(
                        Icons.location_on,
                        size: 44,
                        color: AppColors.primary,
                        shadows: [
                          BoxShadow(
                            color: Color(0x66F25C05),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.helperText,
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Botón confirmar ubicación
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: (widget.ubicacionConfirmada
                        ? AppColors.success
                        : AppColors.primary)
                    .withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              widget.onUbicacionConfirmadaChanged(!widget.ubicacionConfirmada);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.ubicacionConfirmada
                  ? AppColors.success
                  : AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.ubicacionConfirmada
                      ? 'Ubicación Confirmada'
                      : 'Confirmar Ubicación',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MapaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fondo = Paint()..color = const Color(0xFFE9ECF1);
    canvas.drawRect(Offset.zero & size, fondo);

    final calles = Paint()
      ..color = const Color(0xFFCFD5DD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final centro = Offset(size.width / 2, size.height / 2);
    for (final r in [40.0, 80.0, 125.0, 175.0]) {
      canvas.drawCircle(centro, r, calles);
    }
    canvas.drawLine(Offset(centro.dx, -20), Offset(centro.dx, size.height + 20), calles);
    canvas.drawLine(Offset(-20, centro.dy), Offset(size.width + 20, centro.dy), calles);
    canvas.drawLine(const Offset(40, 20), Offset(size.width - 40, size.height - 20), calles);
    canvas.drawLine(Offset(size.width - 40, 20), Offset(40, size.height - 20), calles);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PinLayoutDelegate extends SingleChildLayoutDelegate {
  final Offset posicionPin;

  _PinLayoutDelegate(this.posicionPin);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // posicionPin.dx e dy varían de 0.0 a 1.0.
    // Queremos que el extremo inferior central del pin (tip) esté en:
    // x = posicionPin.dx * size.width
    // y = posicionPin.dy * size.height
    // Por lo tanto, desplazamos x por la mitad del ancho del hijo,
    // y desplazamos y por el alto total del hijo.
    final x = posicionPin.dx * size.width - childSize.width / 2;
    final y = posicionPin.dy * size.height - childSize.height;
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(covariant _PinLayoutDelegate oldDelegate) {
    return oldDelegate.posicionPin != posicionPin;
  }
}

