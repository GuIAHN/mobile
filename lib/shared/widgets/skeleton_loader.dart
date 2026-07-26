import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Bloque con efecto shimmer, usado para armar skeleton screens mientras
/// se espera una respuesta de la API (evita pantallas en blanco/spinners
/// largos en listas — patrón estándar 2026 de carga progresiva).
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
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
                colors: const [
                  AppColors.grey200,
                  AppColors.grey100,
                  AppColors.grey200,
                ],
                stops: const [0.35, 0.5, 0.65],
              ).createShader(rect);
            },
            child: Container(
              width: widget.width,
              height: widget.height,
              color: AppColors.grey200,
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Badge de estado + Timer + Hora
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 100, height: 22, borderRadius: 6),
              Row(
                children: [
                  SkeletonBox(width: 80, height: 20, borderRadius: 6),
                  SizedBox(width: 8),
                  SkeletonBox(width: 45, height: 12, borderRadius: 4),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Main Row: Foto del repuesto + Título de vehículo + Chips
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 60, height: 60, borderRadius: 12),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 170, height: 16, borderRadius: 6),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        SkeletonBox(width: 110, height: 20, borderRadius: 6),
                        SizedBox(width: 6),
                        SkeletonBox(width: 65, height: 20, borderRadius: 6),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Store view extra: Info del cliente y cercanía km
          if (isStore) ...[
            const Row(
              children: [
                SkeletonBox(width: 22, height: 22, borderRadius: 11),
                SizedBox(width: 8),
                SkeletonBox(width: 110, height: 13, borderRadius: 4),
                Spacer(),
                SkeletonBox(width: 60, height: 18, borderRadius: 6),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // 4. Detalle/Nota box skeleton
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const SkeletonBox(width: double.infinity, height: 14, borderRadius: 4),
          ),
          const SizedBox(height: 12),

          // 5. Footer: Botón de Acción ("COTIZAR AHORA") o Banner de Mejor Oferta
          if (isStore) ...[
            const SkeletonBox(width: double.infinity, height: 40, borderRadius: 10),
          ] else ...[
            const SkeletonBox(width: double.infinity, height: 36, borderRadius: 10),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 160, height: 12, borderRadius: 4),
                SkeletonBox(width: 14, height: 14, borderRadius: 4),
              ],
            ),
          ],
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 92, height: 92, borderRadius: 14),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 110, height: 20, borderRadius: 6),
                SizedBox(height: 10),
                SkeletonBox(width: 140, height: 13, borderRadius: 6),
                SizedBox(height: 12),
                Row(
                  children: [
                    SkeletonBox(width: 56, height: 20, borderRadius: 8),
                    SizedBox(width: 6),
                    SkeletonBox(width: 56, height: 20, borderRadius: 8),
                  ],
                ),
              ],
            ),
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
