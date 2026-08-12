import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Iconos ilustrados (CustomPaint) para las categorías del home.
/// Cada categoría tiene su color propio para diferenciarse visualmente.

// ── Repuestos ───────────────────────────────────────────────────────────────

class RepuestosIcon extends StatelessWidget {
  final double size;
  final Color color;

  const RepuestosIcon({
    super.key,
    this.size = 40,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RepuestosPainter(color),
    );
  }
}

class _RepuestosPainter extends CustomPainter {
  final Color color;

  _RepuestosPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48;

    final boxFill = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeJoin = StrokeJoin.round;
    final pieceFill = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final arrow = Paint()
      ..color = color
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round;

    // Caja exterior
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8 * s, 14 * s, 32 * s, 24 * s),
      Radius.circular(4 * s),
    );
    canvas.drawRRect(boxRect, boxFill);
    canvas.drawRRect(boxRect, stroke);

    // Pieza dentro
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(14 * s, 20 * s, 10 * s, 12 * s),
        Radius.circular(2 * s),
      ),
      pieceFill,
    );

    // Rueda / engranaje
    canvas.drawCircle(Offset(32 * s, 24 * s), 5 * s, stroke);
    canvas.drawCircle(Offset(32 * s, 24 * s), 2 * s, dot);

    // Flechas de entrada
    canvas.drawLine(Offset(12 * s, 10 * s), Offset(16 * s, 14 * s), arrow);
    canvas.drawLine(Offset(36 * s, 10 * s), Offset(32 * s, 14 * s), arrow);
  }

  @override
  bool shouldRepaint(covariant _RepuestosPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ── Talleres ────────────────────────────────────────────────────────────────

class TalleresIcon extends StatelessWidget {
  final double size;
  final Color color;

  const TalleresIcon({
    super.key,
    this.size = 40,
    this.color = AppColors.tertiary,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TalleresPainter(color),
    );
  }
}

class _TalleresPainter extends CustomPainter {
  final Color color;

  _TalleresPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48;

    final fill = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeJoin = StrokeJoin.round;
    final doorFill = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final windowDot = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = color
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round;

    // Edificio con techo inclinado
    final building = Path()
      ..moveTo(8 * s, 38 * s)
      ..lineTo(8 * s, 18 * s)
      ..lineTo(24 * s, 8 * s)
      ..lineTo(40 * s, 18 * s)
      ..lineTo(40 * s, 38 * s)
      ..close();
    canvas.drawPath(building, fill);
    canvas.drawPath(building, stroke);

    // Portón
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(18 * s, 28 * s, 12 * s, 10 * s),
        Radius.circular(2 * s),
      ),
      doorFill,
    );
    canvas.drawLine(Offset(22 * s, 32 * s), Offset(26 * s, 32 * s), line);

    // Ventanas
    canvas.drawCircle(Offset(14 * s, 22 * s), 2 * s, windowDot);
    canvas.drawCircle(Offset(34 * s, 22 * s), 2 * s, windowDot);

    // Antena / luz superior
    canvas.drawLine(
      Offset(24 * s, 8 * s),
      Offset(24 * s, 4 * s),
      Paint()
        ..color = color
        ..strokeWidth = 2.5 * s
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(24 * s, 4 * s),
      2 * s,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _TalleresPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ── Mecánicos ───────────────────────────────────────────────────────────────

class MecanicosIcon extends StatelessWidget {
  final double size;
  final Color color;

  const MecanicosIcon({
    super.key,
    this.size = 40,
    this.color = AppColors.celeste,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MecanicosPainter(color),
    );
  }
}

class _MecanicosPainter extends CustomPainter {
  final Color color;

  _MecanicosPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48;

    final headFill = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final headStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s;
    final bodyFill = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final bodyStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeJoin = StrokeJoin.round;
    final line = Paint()
      ..color = color
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round;
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Cabeza
    canvas.drawCircle(Offset(24 * s, 16 * s), 7 * s, headFill);
    canvas.drawCircle(Offset(24 * s, 16 * s), 7 * s, headStroke);

    // Cuerpo / overol
    final body = Path()
      ..moveTo(17 * s, 28 * s)
      ..cubicTo(17 * s, 28 * s, 20 * s, 26 * s, 24 * s, 26 * s)
      ..cubicTo(28 * s, 26 * s, 31 * s, 28 * s, 31 * s, 28 * s)
      ..lineTo(33 * s, 40 * s)
      ..cubicTo(33 * s, 41 * s, 32 * s, 42 * s, 31 * s, 42 * s)
      ..lineTo(17 * s, 42 * s)
      ..cubicTo(16 * s, 42 * s, 15 * s, 41 * s, 15 * s, 40 * s)
      ..close();
    canvas.drawPath(body, bodyFill);
    canvas.drawPath(body, bodyStroke);

    // Detalles del overol
    canvas.drawLine(Offset(20 * s, 34 * s), Offset(28 * s, 34 * s), line);
    canvas.drawLine(Offset(21 * s, 38 * s), Offset(27 * s, 38 * s), line);

    // Ojos
    canvas.drawCircle(Offset(21 * s, 15 * s), 1.5 * s, dot);
    canvas.drawCircle(Offset(27 * s, 15 * s), 1.5 * s, dot);

    // Sonrisa
    final smile = Path()
      ..moveTo(22 * s, 19 * s)
      ..quadraticBezierTo(24 * s, 21 * s, 26 * s, 19 * s);
    canvas.drawPath(
      smile,
      Paint()
        ..color = color
        ..strokeWidth = 1.5 * s
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _MecanicosPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ── Dashboard (tiendas) ─────────────────────────────────────────────────────

class DashboardIcon extends StatelessWidget {
  final double size;
  final Color color;

  const DashboardIcon({
    super.key,
    this.size = 40,
    this.color = AppColors.success,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DashboardPainter(color),
    );
  }
}

class _DashboardPainter extends CustomPainter {
  final Color color;

  _DashboardPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48;

    final barFill = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final barSolid = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final axis = Paint()
      ..color = color
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round;

    // Ejes
    canvas.drawLine(Offset(10 * s, 8 * s), Offset(10 * s, 38 * s), axis);
    canvas.drawLine(Offset(10 * s, 38 * s), Offset(40 * s, 38 * s), axis);

    // Barras
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(15 * s, 26 * s, 6 * s, 12 * s),
        Radius.circular(2 * s),
      ),
      barFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(24 * s, 18 * s, 6 * s, 20 * s),
        Radius.circular(2 * s),
      ),
      barSolid,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(33 * s, 12 * s, 6 * s, 26 * s),
        Radius.circular(2 * s),
      ),
      barFill,
    );
  }

  @override
  bool shouldRepaint(covariant _DashboardPainter oldDelegate) =>
      oldDelegate.color != color;
}
