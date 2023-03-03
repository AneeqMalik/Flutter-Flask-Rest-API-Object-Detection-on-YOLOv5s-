import 'dart:ui';

import 'package:flutter/material.dart';

class BoxPainter extends CustomPainter {
  final dynamic predictions;

  BoxPainter(this.predictions);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
    ];

    if (predictions != null) {
      for (var i = 0; i < predictions.length; i++) {
        final prediction = predictions[i];
        final bbox = prediction['bbox'];

        final left = bbox['xmin'].toDouble();
        final top = bbox['ymin'].toDouble();
        final right = bbox['xmax'].toDouble();
        final bottom = bbox['ymax'].toDouble();

        final rect = Rect.fromLTWH(
          left / 640 * width,
          top / 640 * height,
          (right - left) / 640 * width,
          (bottom - top) / 640 * height,
        );

        final paint = Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        final labelPaint = Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.fill
          ..strokeWidth = 2.0;

        canvas.drawRect(rect, paint);

        final label = '${prediction['name']} (${prediction['confidence']})';
        final labelOffset = Offset(
          left / 640 * width,
          top / 480 * height - 20,
        );
        canvas.drawRect(
          Rect.fromPoints(
            labelOffset,
            Offset(
              labelOffset.dx + label.length * 8,
              labelOffset.dy + 20,
            ),
          ),
          labelPaint,
        );

        final textStyle = TextStyle(
          color: Colors.white,
          fontSize: 14.0,
        );
        final textSpan = TextSpan(
          text: label,
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(
          minWidth: 0,
          maxWidth: size.width,
        );
        textPainter.paint(
          canvas,
          Offset(
            labelOffset.dx + 4,
            labelOffset.dy + 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(BoxPainter oldDelegate) => false;
}
