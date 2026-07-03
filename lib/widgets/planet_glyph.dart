import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ensartede planet-symboler tegnet med CustomPainter i stedet for Unicode.
///
/// Det undgår at Venus/Mars/Måne osv. får forskellig vægt/stil på Android,
/// Linux og iOS på grund af font-fallback.
class PlanetGlyph extends StatelessWidget {
  final String planet;
  final double size;
  final Color color;
  final double strokeWidth;

  const PlanetGlyph({
    super.key,
    required this.planet,
    this.size = 22,
    this.color = AppColors.text,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: PlanetGlyphPainter(
          planet: planet,
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class PlanetGlyphPainter extends CustomPainter {
  final String planet;
  final Color color;
  final double strokeWidth;

  const PlanetGlyphPainter({
    required this.planet,
    this.color = AppColors.text,
    this.strokeWidth = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final side = min(size.width, size.height);
    final scale = side / 100.0;
    final dx = (size.width - side) / 2;
    final dy = (size.height - side) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (planet) {
      case 'Sol':
      case 'Sun':
        _drawSun(canvas, stroke, fill);
        break;
      case 'Måne':
      case 'Moon':
        _drawMoon(canvas, stroke);
        break;
      case 'Merkur':
      case 'Mercury':
        _drawMercury(canvas, stroke);
        break;
      case 'Venus':
        _drawVenus(canvas, stroke);
        break;
      case 'Mars':
        _drawMars(canvas, stroke);
        break;
      case 'Jupiter':
        _drawJupiter(canvas, stroke);
        break;
      case 'Saturn':
        _drawSaturn(canvas, stroke);
        break;
      default:
        _drawFallback(canvas, stroke);
        break;
    }

    canvas.restore();
  }

  void _drawSun(Canvas canvas, Paint stroke, Paint fill) {
    canvas.drawCircle(const Offset(50, 50), 26, stroke);
    canvas.drawCircle(const Offset(50, 50), 4.5, fill);
  }

  void _drawMoon(Canvas canvas, Paint stroke) {
    final path = Path()
      ..moveTo(62, 18)
      ..cubicTo(34, 27, 25, 50, 34, 73)
      ..cubicTo(42, 89, 58, 88, 69, 79)
      ..moveTo(62, 18)
      ..cubicTo(47, 34, 47, 65, 69, 79);
    canvas.drawPath(path, stroke);
  }

  void _drawMercury(Canvas canvas, Paint stroke) {
    final crescent = Path()
      ..moveTo(29, 23)
      ..cubicTo(38, 38, 62, 38, 71, 23);
    canvas.drawPath(crescent, stroke);
    canvas.drawCircle(const Offset(50, 45), 19, stroke);
    canvas.drawLine(const Offset(50, 64), const Offset(50, 87), stroke);
    canvas.drawLine(const Offset(36, 76), const Offset(64, 76), stroke);
  }

  void _drawVenus(Canvas canvas, Paint stroke) {
    canvas.drawCircle(const Offset(50, 36), 21, stroke);
    canvas.drawLine(const Offset(50, 57), const Offset(50, 87), stroke);
    canvas.drawLine(const Offset(34, 72), const Offset(66, 72), stroke);
  }

  void _drawMars(Canvas canvas, Paint stroke) {
    canvas.drawCircle(const Offset(39, 61), 21, stroke);
    canvas.drawLine(const Offset(54, 46), const Offset(78, 22), stroke);
    canvas.drawLine(const Offset(78, 22), const Offset(78, 43), stroke);
    canvas.drawLine(const Offset(78, 22), const Offset(57, 22), stroke);
  }

  void _drawJupiter(Canvas canvas, Paint stroke) {
    final curve = Path()
      ..moveTo(30, 28)
      ..cubicTo(48, 18, 58, 33, 48, 48)
      ..cubicTo(43, 56, 34, 60, 25, 57);
    canvas.drawPath(curve, stroke);
    canvas.drawLine(const Offset(57, 22), const Offset(57, 84), stroke);
    canvas.drawLine(const Offset(33, 61), const Offset(76, 61), stroke);
  }

  void _drawSaturn(Canvas canvas, Paint stroke) {
    canvas.drawLine(const Offset(45, 18), const Offset(45, 82), stroke);
    canvas.drawLine(const Offset(31, 33), const Offset(61, 33), stroke);
    final hook = Path()
      ..moveTo(45, 51)
      ..cubicTo(65, 48, 73, 62, 62, 73)
      ..cubicTo(53, 82, 39, 81, 34, 72);
    canvas.drawPath(hook, stroke);
  }

  void _drawFallback(Canvas canvas, Paint stroke) {
    canvas.drawCircle(const Offset(50, 50), 28, stroke);
  }

  @override
  bool shouldRepaint(covariant PlanetGlyphPainter oldDelegate) {
    return oldDelegate.planet != planet ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
