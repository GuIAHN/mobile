import 'package:flutter/material.dart';

/// Anima la entrada de un ítem de lista con fade+slide corto, escalonado
/// según su posición (patrón estándar 2026 para listados de resultados).
class StaggeredEntrance extends StatefulWidget {
  final int index;
  final Widget child;
  final int staggerMs;

  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.staggerMs = 40,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void initState() {
    super.initState();
    final delayMs = (widget.index * widget.staggerMs).clamp(0, 240);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
