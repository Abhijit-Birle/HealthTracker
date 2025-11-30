import 'package:flutter/material.dart';
import 'dart:math' as math;

class NutritionRingPainter extends CustomPainter {
  final double protein;
  final double carbs;
  final double fat;

  NutritionRingPainter({required this.protein, required this.carbs, required this.fat});

  @override
  void paint(Canvas canvas, Size size) {
    double total = protein + carbs + fat;
    double startAngle = -math.pi / 2;
    double center = size.width / 2;
    double radius = size.width / 2 - 10;
    Rect rect = Rect.fromCircle(center: Offset(center, center), radius: radius);

    Paint paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round;

    // Protein (Purple)
    paint.color = const Color(0xFFE040FB);
    double sweep1 = (protein / total) * 2 * math.pi;
    canvas.drawArc(rect, startAngle, sweep1, false, paint);

    // Carbs (Cyan)
    startAngle += sweep1;
    paint.color = const Color(0xFF00E676);
    double sweep2 = (carbs / total) * 2 * math.pi;
    canvas.drawArc(rect, startAngle, sweep2, false, paint);

    // Fat (Blue)
    startAngle += sweep2;
    paint.color = const Color(0xFF00B0FF);
    double sweep3 = (fat / total) * 2 * math.pi;
    canvas.drawArc(rect, startAngle, sweep3, false, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}