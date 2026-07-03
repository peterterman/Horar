import 'dart:math';

import 'package:flutter/material.dart';

import '../models/horary_models.dart';
import '../services/astro_calculator.dart';
import 'planet_glyph.dart';
import '../theme/app_colors.dart';

class ZodiacWheel extends StatelessWidget {
  final HoraryChart chart;

  const ZodiacWheel({super.key, required this.chart});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ZodiacWheelPainter(chart),
      child: const SizedBox.expand(),
    );
  }
}

class _ZodiacWheelPainter extends CustomPainter {
  final HoraryChart chart;

  _ZodiacWheelPainter(this.chart);

  static const signs = ['♈', '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓'];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.43;
    final asc = chart.houses.isNotEmpty ? chart.houses.first.longitude : 0.0;

    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.text;
    final housePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.divider;
    final planetPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.brown;

    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius * 0.72, circlePaint);

    for (var i = 0; i < 12; i++) {
      final signLon = i * 30.0 + 15.0;
      final p = _point(center, radius * 0.88, signLon, asc);
      _drawText(canvas, signs[i], p, 20, TextAlign.center);
    }

    for (final house in chart.houses) {
      final outer = _point(center, radius, house.longitude, asc);
      final inner = _point(center, radius * 0.30, house.longitude, asc);
      canvas.drawLine(inner, outer, housePaint);

      final labelPoint = _point(center, radius * 0.60, house.longitude + 10, asc);
      _drawText(canvas, house.number.toString(), labelPoint, 11, TextAlign.center);
    }

    for (var i = 0; i < chart.planets.length; i++) {
      final planet = chart.planets[i];
      final r = radius * (0.48 + (i % 3) * 0.07);
      final p = _point(center, r, planet.longitude, asc);
      canvas.drawCircle(p, 3.5, planetPaint);
      _drawPlanetGlyph(canvas, planet.name, p.translate(0, -16), 24);
    }

    final ascPoint = _point(center, radius + 8, asc, asc);
    _drawText(canvas, 'AC', ascPoint, 12, TextAlign.center);
    final mc = chart.houses.length >= 10 ? chart.houses[9].longitude : asc + 90;
    final mcPoint = _point(center, radius + 8, mc, asc);
    _drawText(canvas, 'MC', mcPoint, 12, TextAlign.center);
  }

  Offset _point(Offset center, double radius, double longitude, double asc) {
    // Ascendanten placeres til venstre. Resten roteres relativt dertil.
    final angle = (180 - _norm(longitude - asc)) * pi / 180;
    return Offset(center.dx + cos(angle) * radius, center.dy + sin(angle) * radius);
  }

  double _norm(double value) {
    var v = value % 360;
    if (v < 0) v += 360;
    return v.toDouble();
  }

  void _drawText(Canvas canvas, String text, Offset center, double fontSize, TextAlign align) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: AppColors.text),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  void _drawPlanetGlyph(Canvas canvas, String planet, Offset center, double size) {
    canvas.save();
    canvas.translate(center.dx - size / 2, center.dy - size / 2);
    PlanetGlyphPainter(planet: planet, color: AppColors.text, strokeWidth: 2)
        .paint(canvas, Size(size, size));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ZodiacWheelPainter oldDelegate) => oldDelegate.chart != chart;
}
