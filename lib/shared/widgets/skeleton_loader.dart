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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SkeletonBox(width: 48, height: 48, borderRadius: 14),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 140, height: 14, borderRadius: 6),
                const SizedBox(height: 8),
                const SkeletonBox(width: 200, height: 11, borderRadius: 6),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SkeletonBox(width: 56, height: 18, borderRadius: 8),
                    const SizedBox(width: 8),
                    SkeletonBox(width: 64, height: 18, borderRadius: 8),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SkeletonBox(width: 38, height: 38, borderRadius: 19),
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

/// Skeleton de una fila de conversación/hilo de chat.
class ThreadCardSkeleton extends StatelessWidget {
  const ThreadCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 76, height: 76, borderRadius: 12),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 120, height: 14, borderRadius: 6),
                const SizedBox(height: 10),
                const SkeletonBox(width: 90, height: 11, borderRadius: 6),
                const SizedBox(height: 10),
                const SkeletonBox(width: 150, height: 12, borderRadius: 6),
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
