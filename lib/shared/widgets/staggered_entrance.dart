import 'dart:async';

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
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // Sin esto, ListView.builder destruye y recrea el State de los ítems que
  // salen del viewport (o de su cacheExtent) y vuelven a entrar al hacer
  // scroll — cada recreación dispara `initState` de nuevo y el ítem se
  // reanima como si fuera la primera vez. AutomaticKeepAlive mantiene el
  // State vivo, así la animación de entrada corre una sola vez.
  @override
  bool get wantKeepAlive => true;

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
  Timer? _delayTimer;
  bool _hasStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.disableAnimationsOf(context)) {
      _delayTimer?.cancel();
      _controller.value = 1;
      _hasStarted = true;
      return;
    }
    if (_hasStarted) return;

    _hasStarted = true;
    final delayMs = (widget.index * widget.staggerMs).clamp(0, 240);
    if (delayMs == 0) {
      _controller.forward();
      return;
    }
    _delayTimer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // requerido por AutomaticKeepAliveClientMixin
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
