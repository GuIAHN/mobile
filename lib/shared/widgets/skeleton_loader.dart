import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Bloque con efecto shimmer, usado para armar skeleton screens mientras
/// se espera una respuesta de la API (evita pantallas en blanco/spinners
/// largos en listas — patrón estándar 2026 de carga progresiva).
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? AppColors.grey200;
    final highlight = widget.highlightColor ?? AppColors.grey100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: ShaderMask(
            shaderCallback: (rect) {
              final dx = _controller.value * 2 - 1;
              return LinearGradient(
                begin: Alignment(-1 - dx, 0),
                end: Alignment(1 - dx, 0),
                colors: [
                  base,
                  highlight,
                  base,
                ],
                stops: const [0.35, 0.5, 0.65],
              ).createShader(rect);
            },
            child: Container(
              width: widget.width,
              height: widget.height,
              color: base,
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton de una fila tipo "card de item" (avatar + 2 líneas + tags).
/// Usado en listados de resultados de búsqueda mientras cargan.
class ItemCardSkeleton extends StatelessWidget {
  const ItemCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SkeletonBox(width: 48, height: 48, borderRadius: 14),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 14, borderRadius: 6),
                SizedBox(height: 8),
                SkeletonBox(width: 200, height: 11, borderRadius: 6),
                SizedBox(height: 10),
                Row(
                  children: [
                    SkeletonBox(width: 56, height: 18, borderRadius: 8),
                    SizedBox(width: 8),
                    SkeletonBox(width: 64, height: 18, borderRadius: 8),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          SkeletonBox(width: 38, height: 38, borderRadius: 19),
        ],
      ),
    );
  }
}

/// Skeleton del banner promocional mientras carga.
class PromoSkeleton extends StatelessWidget {
  const PromoSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonBox(height: 168, borderRadius: 20);
  }
}

/// Skeleton de una fila de conversación/hilo de chat (adaptado a vista Tienda o Consumidor).
class ThreadCardSkeleton extends StatelessWidget {
  final bool isStore;

  const ThreadCardSkeleton({super.key, this.isStore = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Geometría idéntica a CardShell (radio 20, padding 16, borde grey100,
      // sombra negro 5%/blur 18/offset (0,6)) para que no haya salto de
      // layout al cargar.
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zona 1: badge de estado + expiración
          const Row(
            children: [
              SkeletonBox(width: 128, height: 25, borderRadius: 8),
              Spacer(),
              SkeletonBox(width: 74, height: 14, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 14),

          // Zona 2: miniatura 64 + título + línea de metadata
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 64, height: 64, borderRadius: 14),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 175, height: 18, borderRadius: 6),
                    SizedBox(height: 6),
                    SkeletonBox(width: 130, height: 14, borderRadius: 4),
                    SizedBox(height: 10),
                    SkeletonBox(width: double.infinity, height: 14, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),

          // Zona 3 (solo tienda): línea de contexto del cliente
          if (isStore) ...[
            const SizedBox(height: 14),
            const SkeletonBox(width: 210, height: 14, borderRadius: 4),
          ],

          // Divisor + footer (CTA en tienda, precio en consumidor)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: AppColors.border),
          ),
          if (isStore)
            const SkeletonBox(width: double.infinity, height: 48, borderRadius: 14)
          else
            const Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 84, height: 12, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(width: 116, height: 19, borderRadius: 6),
                  ],
                ),
                Spacer(),
                SkeletonBox(width: 96, height: 14, borderRadius: 4),
              ],
            ),
        ],
      ),
    );
  }
}

/// Skeleton de una card de oferta (estilo marketplace): imagen de producto
/// grande + precio + tienda + chips.
class OfferCardSkeleton extends StatelessWidget {
  const OfferCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Geometría idéntica a CardShell (radio 20, padding 16, borde grey100,
      // sombra negro 5%/blur 18/offset (0,6)) para que no haya salto de
      // layout al cargar.
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cuerpo: miniatura 88 + tienda + metadata + precio protagonista
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 88, height: 88, borderRadius: 14),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 150, height: 18, borderRadius: 6),
                    SizedBox(height: 6),
                    SkeletonBox(width: 185, height: 14, borderRadius: 4),
                    SizedBox(height: 10),
                    SkeletonBox(width: 132, height: 26, borderRadius: 6),
                  ],
                ),
              ),
            ],
          ),

          // Divisor + footer: mensaje + CTA
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: AppColors.border),
          ),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 14, borderRadius: 4)),
              SizedBox(width: 12),
              SkeletonBox(width: 104, height: 40, borderRadius: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton de una burbuja de mensaje (alterna lado izq/der).
class MessageBubbleSkeleton extends StatelessWidget {
  final bool alignRight;

  const MessageBubbleSkeleton({super.key, this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SkeletonBox(
          width: alignRight ? 160 : 210,
          height: 44,
          borderRadius: 16,
        ),
      ),
    );
  }
}
