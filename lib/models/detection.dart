import 'package:flutter/material.dart';

class Detection {
  final double x;
  final double y;
  final double width;
  final double height;
  final String colorLabel;
  final double confidence;
  final Color color;

  Detection({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.colorLabel,
    required this.confidence,
    required this.color,
  });

  @override
  String toString() {
    return 'Detection: $colorLabel ($confidence)';
  }
}
