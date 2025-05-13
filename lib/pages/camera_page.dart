import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/detection_service.dart';
import '../models/detection.dart';
import '../widgets/detection_overlay.dart';
import '../constants/colors.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late List<CameraDescription> cameras;
  CameraController? controller;
  bool isDetecting = false;
  List<Detection> detections = [];
  bool isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller!.initialize();
      await controller!.setFlashMode(FlashMode.off);
      _startDetection();
      setState(() {});
    } catch (e) {
      debugPrint("Camera Error: $e");
      _showErrorDialog("Error initializing camera.");
    }
  }

  void _startDetection() {
    if (controller == null) return;

    controller!.startImageStream((CameraImage image) async {
      if (!isDetecting) {
        isDetecting = true;
        try {
          final results = await DetectionService.detect(image);
          if (mounted) {
            setState(() {
              detections = results;
            });
          }
        } catch (error) {
          debugPrint("Detection error: $error");
        } finally {
          isDetecting = false;
        }
      }
    });
  }

  void _toggleFlash() async {
    if (controller == null) return;

    try {
      final newMode = isFlashOn ? FlashMode.off : FlashMode.torch;
      await controller!.setFlashMode(newMode);
      setState(() {
        isFlashOn = !isFlashOn;
      });
    } catch (e) {
      debugPrint("Flash toggle error: $e");
    }
  }

  void _toggleCamera() async {
    if (controller == null || cameras.length < 2) return;

    final newCameraIndex = controller!.description == cameras[0] ? 1 : 0;
    
    try {
      controller?.dispose();
      controller = CameraController(
        cameras[newCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller!.initialize();
      _startDetection();
      setState(() {});
    } catch (e) {
      debugPrint("Camera switch error: $e");
      _showErrorDialog("Error switching camera.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    DetectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Detection'),
        backgroundColor: Colors.black.withOpacity(0.7),
        actions: [
          if (cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: _toggleCamera,
            ),
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller!),
          DetectionOverlay(
            detections: detections,
            previewSize: controller!.value.previewSize!,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Detected Colors: ${detections.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  ...detections.map((d) => Text(
                    '${d.colorLabel}: ${(d.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: d.color,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
