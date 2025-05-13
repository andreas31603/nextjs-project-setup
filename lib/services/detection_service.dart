import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/detection.dart';
import '../constants/colors.dart';

class DetectionService {
  static Interpreter? _interpreter;
  static const int INPUT_SIZE = 416; // Standard YOLO input size

  /// Loads the YOLO model if not already loaded
  static Future<void> loadModel() async {
    try {
      _interpreter ??= await Interpreter.fromAsset('assets/yolo_model.tflite');
    } catch (e) {
      throw Exception("Failed to load model: $e");
    }
  }

  /// Processes a CameraImage and returns color detections
  static Future<List<Detection>> detect(CameraImage image) async {
    if (_interpreter == null) {
      await loadModel();
    }

    // Convert CameraImage to input tensor
    final inputArray = await _preProcessImage(image);

    // Prepare output buffer as List
    var output = List.filled(1000, 0.0).reshape([1, 1000]); // Adjust size as per model output

    // Run inference
    _interpreter!.run(inputArray, output);

    // Flatten output list
    List<double> outputList = output.expand((e) => e).toList();

    // Process results
    return _processDetections(outputList);
  }

  /// Preprocesses the camera image into the format required by the model
  static Future<List<List<List<double>>>> _preProcessImage(CameraImage image) async {
    // Convert YUV420 to RGB
    final int width = image.width;
    final int height = image.height;

    // Convert YUV420 to RGB bytes
    final rgbBytes = _convertYUV420ToRGB(image);

    // Resize to INPUT_SIZE x INPUT_SIZE
    final resizedBytes = await _resizeImage(rgbBytes, width, height, INPUT_SIZE, INPUT_SIZE);

    // Normalize pixels to 0-1 and convert to List<List<List<double>>> shape [1, INPUT_SIZE, INPUT_SIZE, 3]
    List<List<List<double>>> input = List.generate(INPUT_SIZE, (y) {
      return List.generate(INPUT_SIZE, (x) {
        int index = (y * INPUT_SIZE + x) * 3;
        return [
          resizedBytes[index] / 255.0,
          resizedBytes[index + 1] / 255.0,
          resizedBytes[index + 2] / 255.0,
        ];
      });
    });

    return [input];
  }

  static Uint8List _convertYUV420ToRGB(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;

    final yBuffer = image.planes[0].bytes;
    final uBuffer = image.planes[1].bytes;
    final vBuffer = image.planes[2].bytes;

    final rgbBuffer = Uint8List(width * height * 3);

    for (int y = 0; y < height; y++) {
      final int uvRow = uvRowStride * (y >> 1);
      for (int x = 0; x < width; x++) {
        final int uvIndex = uvRow + (x >> 1) * uvPixelStride;

        final int yIndex = y * width + x;
        final int yValue = yBuffer[yIndex];

        final int uValue = uBuffer[uvIndex];
        final int vValue = vBuffer[uvIndex];

        int r = (yValue + (1.370705 * (vValue - 128))).round();
        int g = (yValue - (0.337633 * (uValue - 128)) - (0.698001 * (vValue - 128))).round();
        int b = (yValue + (1.732446 * (uValue - 128))).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        final int rgbIndex = yIndex * 3;
        rgbBuffer[rgbIndex] = r;
        rgbBuffer[rgbIndex + 1] = g;
        rgbBuffer[rgbIndex + 2] = b;
      }
    }
    return rgbBuffer;
  }

  static Future<Uint8List> _resizeImage(Uint8List data, int srcWidth, int srcHeight, int dstWidth, int dstHeight) async {
    // Use image package for resizing
    // Since we cannot import 'package:image/image.dart' here, we will implement a simple nearest neighbor resize

    Uint8List resized = Uint8List(dstWidth * dstHeight * 3);

    for (int y = 0; y < dstHeight; y++) {
      int srcY = (y * srcHeight / dstHeight).floor();
      for (int x = 0; x < dstWidth; x++) {
        int srcX = (x * srcWidth / dstWidth).floor();

        int srcIndex = (srcY * srcWidth + srcX) * 3;
        int dstIndex = (y * dstWidth + x) * 3;

        resized[dstIndex] = data[srcIndex];
        resized[dstIndex + 1] = data[srcIndex + 1];
        resized[dstIndex + 2] = data[srcIndex + 2];
      }
    }
    return resized;
  }

  /// Process raw detection results into Detection objects
  static List<Detection> _processDetections(List<double> modelOutput) {
    List<Detection> detections = [];

    // Process model output based on your YOLO model's specific output format
    // This is a simplified example - you'll need to adjust based on your model

    final numDetections = modelOutput.isNotEmpty ? modelOutput[0].toInt() : 0;
    for (var i = 0; i < numDetections; i++) {
      final baseIndex = i * 6; // Assuming output format: [x, y, width, height, class_id, confidence]

      if (baseIndex + 5 >= modelOutput.length) break;

      final x = modelOutput[baseIndex + 0];
      final y = modelOutput[baseIndex + 1];
      final width = modelOutput[baseIndex + 2];
      final height = modelOutput[baseIndex + 3];
      final classId = modelOutput[baseIndex + 4].toInt();
      final confidence = modelOutput[baseIndex + 5];

      if (confidence > 0.5 && classId < ColorConstants.colorLabels.length) {
        final colorLabel = ColorConstants.colorLabels[classId];
        final color = ColorConstants.colorMap[colorLabel]!;

        detections.add(Detection(
          x: x,
          y: y,
          width: width,
          height: height,
          colorLabel: colorLabel,
          confidence: confidence,
          color: color,
        ));
      }
    }

    return detections;
  }

  /// Cleanup resources
  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
