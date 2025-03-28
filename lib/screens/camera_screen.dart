import 'package:face_condition_detector/lighting_analyzer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/face_detection_model.dart';
import '../services/camera_service.dart';
import '../services/face_detector_service.dart';
import '../services/tensorflow_service.dart';
import '../widgets/camera_view.dart';
import '../widgets/condition_display.dart';
import '../widgets/analysis_overlay.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  bool _isCameraPermissionGranted = false;
  bool _isInitialized = false;
  bool _isBusy = false;

  late CameraService _cameraService;
  late FaceDetectorService _faceDetectorService;
  late TensorFlowService _tensorFlowService;
  late FaceDetectionModel _model;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _checkPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cameraService = Provider.of<CameraService>(context);
    _faceDetectorService = Provider.of<FaceDetectorService>(context);
    _tensorFlowService = Provider.of<TensorFlowService>(context);
    _model = Provider.of<FaceDetectionModel>(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize the camera
    if (_cameraService.controller == null || !_cameraService.controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeServices() async {
    try {
      await _faceDetectorService.initialize();
      await _tensorFlowService.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.camera.request();
    setState(() {
      _isCameraPermissionGranted = status.isGranted;
    });

    if (_isCameraPermissionGranted) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (!_isInitialized || !_isCameraPermissionGranted) {
      return;
    }

    try {
      await _cameraService.initialize();
      _startImageStream();
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _startImageStream() {
    _cameraService.startImageStream((CameraImage image) {
      if (_isBusy) return;

      _isBusy = true;
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage image) async {
    try {
      await _faceDetectorService.processImage(image, _cameraService.cameraDescription);
      
      if (_faceDetectorService.faces.isNotEmpty) {
        _model.faceDetected = true;
        
        if (!_model.isProcessing) {
          _model.isProcessing = true;
          
          // Process emotion, tiredness, and stress
          await _tensorFlowService.processImage(
            image,
            _faceDetectorService.faces.first,
            _cameraService.cameraDescription,
          );
          
          _model.updateFacialCondition(
            faceData: _faceDetectorService.faces.first,
            emotionData: _tensorFlowService.emotionData,
            tiredness: _tensorFlowService.tirednessScore,
            stress: _tensorFlowService.stressScore,
            lightingCondition: await _tensorFlowService.getLightingCondition(image) as LightingCondition,
          );
          
          _model.isProcessing = false;
        }
      } else {
        _model.faceDetected = false;
      }
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Condition Detector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_camera),
            onPressed: _cameraService.switchCamera,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Show settings dialog
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_isCameraPermissionGranted) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.no_photography, 
              size: 100, 
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera permission is required',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _checkPermissions,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    if (_cameraService.controller == null || !_cameraService.controller!.value.isInitialized) {
      return const Center(
        child: Text('Camera initialization failed'),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        CameraView(cameraService: _cameraService, controller: _cameraService.controller!),
        
        // Face overlay for detected faces
        if (_model.faceDetected && _faceDetectorService.faces.isNotEmpty)
          AnalysisOverlay(
            face: _faceDetectorService.faces.first,
            previewSize: _cameraService.previewSize,
            screenSize: MediaQuery.of(context).size, condition: null, lightingCondition: '',
          ),
        
        // Display condition information
        ConditionDisplay(facialCondition: null, lightingCondition: '', faceDetected: _model.faceDetected      ),
      ]
    );
  }
}