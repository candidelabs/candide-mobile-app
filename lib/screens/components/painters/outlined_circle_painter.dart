import 'package:flutter/material.dart';

class OutlinedCirclePainter extends CustomPainter {
  Color color;

  OutlinedCirclePainter({required this.color});


  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawOval(
      Rect.fromLTWH(0 - (size.width * 0.05), 0 - (size.height * 0.05), size.width * 1.1, size.height * 1.1),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}