import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/face_detection_model.dart';
import '../widgets/camera_view.dart';
import '../widgets/face_overlay.dart';
import '../widgets/condition_display.dart';
import '../services/camera_service.dart';
import '../services/face_detector_service.dart';
import '../services/tensorflow_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  bool _isPermissionGranted = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraService = Provider.of<CameraService>(context, listen: false);
    
    // If app is resumed but camera was previously stopped, reinitialize
    if (state == AppLifecycleState.resumed && 
        _isPermissionGranted && 
        !cameraService.isInitialized) {
      _initializeServices();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _isPermissionGranted = status == PermissionStatus.granted;
    });
    
    if (_isPermissionGranted) {
      await _initializeServices();
    }
  }

  Future<void> _initializeServices() async {
    try {
      final cameraService = Provider.of<CameraService>(context, listen: false);
      final faceDetectorService = Provider.of<FaceDetectorService>(context, listen: false);
      final tensorflowService = Provider.of<TensorFlowService>(context, listen: false);
      
      await cameraService.initialize();
      await faceDetectorService.initialize();
      await tensorflowService.initialize();
      
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      print('Error initializing services: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initializing camera: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionGranted) {
      return _buildPermissionDeniedScreen();
    }

    if (_isInitializing) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Condition Detector'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          const CameraView(),
          Consumer<FaceDetectionModel>(
            builder: (context, model, child) {
              if (model.face != null) {
                return FaceOverlay(face: model.face!);
              }
              return Container();
            },
          ),
          const ConditionDisplay(),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.camera_alt_off,
              color: Colors.red,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera permission is required',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _requestCameraPermission,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      ),
    );
  }
}
