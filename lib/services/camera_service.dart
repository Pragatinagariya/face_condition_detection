import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef CameraImageCallback = Function(CameraImage image);

class CameraService {
  CameraController? _controller;
  CameraDescription _camera;
  CameraImageCallback? _imageStreamCallback;
  Size? _previewSize;
  bool _isDisposed = false;

  CameraService({required CameraDescription camera}) : _camera = camera;

  CameraController? get controller => _controller;
  CameraDescription get cameraDescription => _camera;
  Size get previewSize => _previewSize ?? const Size(640, 480);
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  Future<void> initialize() async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      _camera,
      kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      _previewSize = Size(
        _controller!.value.previewSize!.height,
        _controller!.value.previewSize!.width,
      );
      _isDisposed = false;
    } catch (e) {
      print('Error initializing camera: $e');
      rethrow;
    }
  }

  void startImageStream(CameraImageCallback callback) {
    if (_controller == null || !_controller!.value.isInitialized) {
      print('Camera controller not initialized');
      return;
    }

    _imageStreamCallback = callback;
    
    try {
      // Using listen instead of startImageStream to fix the error
      _controller!.startImageStream((CameraImage image) {
        if (_imageStreamCallback != null) {
          _imageStreamCallback!(image);
        }
      });
    } catch (e) {
      print('Error starting image stream: $e');
    }
  }

  void stopImageStream() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      _controller!.stopImageStream();
    } catch (e) {
      print('Error stopping image stream: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      final cameras = await availableCameras();
      CameraDescription newCamera;
      
      // Switch between front and back cameras
      if (_camera.lensDirection == CameraLensDirection.front) {
        newCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
      } else {
        newCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
      }
      
      if (newCamera != _camera) {
        _camera = newCamera;
        
        // Save the callback before re-initialization
        final savedCallback = _imageStreamCallback;
        
        // Re-initialize with the new camera
        await initialize();
        
        // Re-start the image stream if it was running before
        if (savedCallback != null) {
          startImageStream(savedCallback);
        }
      }
    } catch (e) {
      print('Error switching camera: $e');
    }
  }

  void dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    
    try {
      if (_controller != null) {
        if (_controller!.value.isStreamingImages) {
          await _controller!.stopImageStream();
        }
        await _controller!.dispose();
        _controller = null;
      }
    } catch (e) {
      print('Error disposing camera: $e');
    }
  }
}