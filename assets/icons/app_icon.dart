import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF009688)
      ..style = PaintingStyle.fill;

    // Draw background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(size.width * 0.25),
      ),
      paint,
    );

    // Draw bus body
    paint.color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.25,
          size.height * 0.375,
          size.width * 0.5,
          size.height * 0.25,
        ),
        Radius.circular(size.width * 0.0625),
      ),
      paint,
    );

    // Draw wheels
    paint.color = const Color(0xFF009688);
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.625),
      size.width * 0.05,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.625),
      size.width * 0.05,
      paint,
    );

    // Draw windows
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.28,
          size.height * 0.4375,
          size.width * 0.44,
          size.height * 0.09375,
        ),
        Radius.circular(size.width * 0.015625),
      ),
      paint,
    );

    // Draw location pin
    final pinPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.1875)
      ..addOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.28125),
          width: size.width * 0.1875,
          height: size.width * 0.1875,
        ),
      );

    paint.color = Colors.white;
    canvas.drawPath(pinPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Helper function to create app icon
Future<void> generateAppIcon(String path, double size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final painter = AppIconPainter();
  painter.paint(canvas, Size(size, size));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData != null) {
    final buffer = byteData.buffer;
    await File(path).writeAsBytes(
      buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
    );
  }
}