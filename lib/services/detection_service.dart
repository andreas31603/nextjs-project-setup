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
    
    // Prepare output arrays
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final outputBuffer = TensorBuffer.createFixedSize(outputShape, TfLiteType.float32);
    
    // Run inference
    _interpreter!.run(inputArray, outputBuffer.buffer);
    
    // Process results
    return _processDetections(outputBuffer.getDoubleList());
  }

  /// Preprocesses the camera image into the format required by the model
  static Future<List<double>> _preProcessImage(CameraImage image) async {
    // Convert YUV to RGB
    final bytes = image.planes.map((plane) => plane.bytes).toList();
    
    // Resize and normalize the image
    // Note: Actual implementation would depend on your image processing requirements
    
    return List<double>.filled(INPUT_SIZE * INPUT_SIZE * 3, 0.0);
  }

  /// Process raw detection results into Detection objects
  static List<Detection> _processDetections(List<double> modelOutput) {
    List<Detection> detections = [];
    
    // Process model output based on your YOLO model's specific output format
    // This is a simplified example - you'll need to adjust based on your model
    
    final numDetections = modelOutput[0];
    for (var i = 0; i < numDetections; i++) {
      final baseIndex = i * 6; // Assuming output format: [x, y, width, height, class_id, confidence]
      
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
