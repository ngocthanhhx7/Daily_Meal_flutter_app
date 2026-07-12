import 'package:flutter/material.dart';

/// The ruled-paper canvas used by the original Daily Meal client.
class DailyMealBackground extends StatelessWidget {
  const DailyMealBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF5F5F5),
      child: CustomPaint(painter: const _RuledPaperPainter(), child: child),
    );
  }
}

class _RuledPaperPainter extends CustomPainter {
  const _RuledPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(0, 0, 0, 0.04)
      ..strokeWidth = 1;
    for (double y = 12; y < size.height; y += 12) {
      canvas.drawLine(Offset(-20, y), Offset(size.width * 1.16, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
