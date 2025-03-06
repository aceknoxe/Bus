import 'package:flutter/material.dart';

class SketchMap extends StatelessWidget {
  const SketchMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: CustomPaint(
        painter: MapPainter(),
        child: Container(), // For tap detection
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw roads
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.8),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.8, size.height * 0.2),
      paint,
    );

    // Draw bus stops
    final stopPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final stops = [
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.5),
    ];

    for (final stop in stops) {
      canvas.drawCircle(stop, 8, stopPaint);
    }

    // Draw buses
    final busPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final buses = [
      Offset(size.width * 0.35, size.height * 0.35),
      Offset(size.width * 0.65, size.height * 0.65),
    ];

    for (final bus in buses) {
      final path = Path()
        ..moveTo(bus.dx, bus.dy - 12)
        ..lineTo(bus.dx - 8, bus.dy + 8)
        ..lineTo(bus.dx + 8, bus.dy + 8)
        ..close();
      canvas.drawPath(path, busPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}