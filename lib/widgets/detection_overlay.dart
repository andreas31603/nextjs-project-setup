import 'package:flutter/material.dart';
import '../models/detection.dart';

class DetectionOverlay extends StatelessWidget {
  final List<Detection> detections;
  final Size previewSize;

  const DetectionOverlay({
    super.key,
    required this.detections,
    required this.previewSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DetectionPainter(detections, previewSize),
      child: Container(),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  final List<Detection> detections;
  final Size previewSize;

  _DetectionPainter(this.detections, this.previewSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final labelPaint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var detection in detections) {
      // Scale coordinates to screen size
      final scaleX = size.width / previewSize.width;
      final scaleY = size.height / previewSize.height;

      final rect = Rect.fromLTWH(
        detection.x * scaleX,
        detection.y * scaleY,
        detection.width * scaleX,
        detection.height * scaleY,
      );

      // Draw bounding box
      paint.color = detection.color.withOpacity(0.8);
      canvas.drawRect(rect, paint);

      // Draw label background
      final label = "${detection.colorLabel} ${(detection.confidence * 100).toStringAsFixed(0)}%";
      textPainter.text = TextSpan(
        text: label,
        style: textStyle,
      );
      textPainter.layout();

      final labelRect = Rect.fromLTWH(
        rect.left,
        rect.top - textPainter.height - 4,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      canvas.drawRect(labelRect, labelPaint);

      // Draw label text
      textPainter.paint(
        canvas,
        Offset(rect.left + 4, rect.top - textPainter.height - 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
