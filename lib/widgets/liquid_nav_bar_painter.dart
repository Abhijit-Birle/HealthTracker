import 'package:flutter/material.dart';

class LiquidNavBarPainter extends CustomPainter {
  final double selectedIndex; // Using double for smooth animation transitions
  final int itemsCount;
  final Color color;

  LiquidNavBarPainter({required this.selectedIndex, required this.itemsCount, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path();

    double itemWidth = size.width / itemsCount;
    double centerX = (selectedIndex * itemWidth) + (itemWidth / 2);

    // Base height of the bar (the solid part at bottom)
    double barTop = 40.0;

    // Draw the main shape
    path.moveTo(0, size.height);
    path.lineTo(0, barTop);

    // Draw line until we get near the "dip"
    path.lineTo(centerX - 50, barTop);

    // The "Liquid" Scoop/Curve
    // This cubic bezier curve creates the smooth dip effect that follows the selected index
    path.cubicTo(
      centerX - 30, barTop,      // Control point 1
      centerX - 30, barTop + 40, // Control point 2 (Downwards)
      centerX, barTop + 40,      // Destination point (Bottom center of dip)
    );
    path.cubicTo(
        centerX + 30, barTop + 40, // Control point 3 (Upwards)
        centerX + 30, barTop,      // Control point 4
        centerX + 50, barTop       // Destination point (Back to bar top)
    );

    path.lineTo(size.width, barTop);
    path.lineTo(size.width, size.height);
    path.close();

    // Draw the filled shape
    canvas.drawPath(path, paint);

    // Optional: Draw a subtle border for better visibility on dark backgrounds
    Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant LiquidNavBarPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.itemsCount != itemsCount ||
        oldDelegate.color != color;
  }
}