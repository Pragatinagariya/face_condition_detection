import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CameraService {
  final CameraDescription camera;
  CameraController? _controller;
  bool _isProcessingFrame = false;

  CameraService({required this.camera});

  bool get isInitialized => _controller?.value.isInitialized ?? false;
  CameraController? get controller => _controller;
  
  Future<void> initialize() async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    // Initialize the camera with the highest resolution and enable face detection
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid 
          ? ImageFormatGroup.yuv420 
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);
    } catch (e) {
      print('Error initializing camera: $e');
      rethrow;
    }
  }

  Future<CameraImage?> takePicture() async {
    if (!isInitialized || _isProcessingFrame) {
      return null;
    }

    _isProcessingFrame = true;
    CameraImage? image;
    
    try {
      image = await _controller!.startImageStream((CameraImage img) {
        _controller!.stopImageStream();
      }).timeout(const Duration(seconds: 2));
    } catch (e) {
      print('Error taking camera image: $e');
    } finally {
      _isProcessingFrame = false;
    }

    return image;
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }

  Future<void> pausePreview() async {
    if (isInitialized) {
      await _controller!.pausePreview();
    }
  }

  Future<void> resumePreview() async {
    if (isInitialized) {
      await _controller!.resumePreview();
    }
  }

  // Adjust camera settings for different lighting conditions
  Future<void> adjustForLighting(double lightingIntensity) async {
    if (!isInitialized) return;

    try {
      // For bright environments (positive intensity)
      if (lightingIntensity > 0.3) {
        // Reduce exposure
        await _controller!.setExposureOffset(-1.0 * lightingIntensity);
      } 
      // For dim environments (negative intensity)
      else if (lightingIntensity < -0.3) {
        // Increase exposure
        await _controller!.setExposureOffset(-2.0 * lightingIntensity);
      }
      // For normal lighting
      else {
        // Reset to auto exposure
        await _controller!.setExposureOffset(0.0);
      }
    } catch (e) {
      print('Error adjusting camera for lighting: $e');
    }
  }
}
