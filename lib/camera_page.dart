import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import 'face_detector_service.dart';
import 'models/face_data.dart';
import 'widgets/camera_view.dart';
import 'widgets/analysis_overlay.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  FaceDetectorService? _faceDetectorService;
  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  bool _isFrontCamera = true;
  int _cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _faceDetectorService?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // App state changed before camera was initialized
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Camera Permission'),
            content: const Text('Camera permission is required to use this app.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _requestCameraPermission();
                },
                child: const Text('Try Again'),
              ),
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _initializeCamera() async {
    await _requestCameraPermission();
    
    try {
      _cameras = await availableCameras();
      
      // Find front camera
      _cameraIndex = _cameras!.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front
      );
      
      // If front camera not found, use the first camera
      if (_cameraIndex == -1) {
        _cameraIndex = 0;
        _isFrontCamera = false;
      }

      await _setupCamera(_cameraIndex);
      
      // Initialize face detector after camera setup
      _faceDetectorService = FaceDetectorService();
      await _faceDetectorService!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } on CameraException catch (e) {
      debugPrint('Camera initialization error: ${e.code}: ${e.description}');
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _setupCamera(int cameraIndex) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    if (_cameras == null || _cameras!.isEmpty) {
      return;
    }

    final camera = _cameras![cameraIndex];
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    
    _cameraController!.startImageStream(_processCameraImage);
  }

  void _processCameraImage(CameraImage image) {
    if (_isProcessing || !mounted) {
      return;
    }

    _isProcessing = true;

    _faceDetectorService?.processImage(
      image, 
      _cameraController!.description.sensorOrientation,
      _isFrontCamera
    ).then((faceData) {
      if (mounted && faceData != null) {
        Provider.of<FaceDataModel>(context, listen: false).updateFaceData(faceData);
      }
      _isProcessing = false;
    }).catchError((error) {
      debugPrint('Error processing image: $error');
      _isProcessing = false;
    });
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length <= 1 || _cameraController == null) {
      return;
    }

    // Toggle camera index
    _cameraIndex = (_cameraIndex + 1) % _cameras!.length;
    _isFrontCamera = _cameras![_cameraIndex].lensDirection == CameraLensDirection.front;

    // Setup new camera
    await _setupCamera(_cameraIndex);
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (!_isCameraInitialized)
            const Center(
              child: CircularProgressIndicator(),
            )
          else ...[
            // Camera preview
            CameraView(controller: _cameraController!),
            
            // Face analysis overlay
            const AnalysisOverlay(),
            
            // Camera controls
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: _toggleCamera,
                child: const Icon(Icons.flip_camera_ios),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
