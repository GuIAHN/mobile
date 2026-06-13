import 'package:flutter/material.dart';

/// Fondo con efecto Ken Burns (zoom lento) para la pantalla de onboarding.
/// Soporta tanto imágenes en red como locales en assets.
class KenBurnsBackground extends StatefulWidget {
  final String imageUrl;
  final bool active;

  const KenBurnsBackground({
    super.key,
    required this.imageUrl,
    required this.active,
  });

  @override
  State<KenBurnsBackground> createState() => _KenBurnsBackgroundState();
}

class _KenBurnsBackgroundState extends State<KenBurnsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    if (widget.active) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant KenBurnsBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0); // Reinicia el zoom al entrar al slide
    } else if (!widget.active && oldWidget.active) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNetwork = widget.imageUrl.startsWith('http://') ||
        widget.imageUrl.startsWith('https://');

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: isNetwork
          ? Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade900),
            )
          : Image.asset(
              widget.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade900),
            ),
    );
  }
}
