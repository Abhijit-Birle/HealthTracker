import 'package:flutter/material.dart';

class LiquidNavBarPainter extends CustomPainter {
  final int selectedIndex;
  final int itemsCount;
  final Color color;

  LiquidNavBarPainter(
      {required this.selectedIndex,
        required this.itemsCount,
        required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path();
    double itemWidth = size.width / itemsCount;
    double centerX = (selectedIndex * itemWidth) + (itemWidth / 2);
    double barTop = 40.0;

    path.moveTo(0, size.height);
    path.lineTo(0, barTop);
    path.lineTo(centerX - 50, barTop);
    path.cubicTo(
        centerX - 30, barTop, centerX - 30, barTop + 40, centerX, barTop + 40);
    path.cubicTo(
        centerX + 30, barTop + 40, centerX + 30, barTop, centerX + 50, barTop);
    path.lineTo(size.width, barTop);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
    Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant LiquidNavBarPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex;
  }
}