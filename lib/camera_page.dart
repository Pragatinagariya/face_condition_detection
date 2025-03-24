import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/facial_condition.dart';
import 'widgets/camera_view.dart';
import 'widgets/face_overlay.dart';
import 'widgets/condition_display.dart';
import 'services/face_detector_service.dart';
import 'utils/lighting_analyzer.dart';
import 'package:flutter/foundation.dart';

class CameraPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const CameraPage({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? cameraController;
  FaceDetectorService? faceDetectorService;
  LightingAnalyzer? lightingAnalyzer;
  
  // Current state variables
  bool _faceDetected = false;
  FacialCondition? _currentCondition;
  String _lightingCondition = "Normal";
  List<Face>? _faces;
  MockFace? _mockFace;
  bool _useMockFace = false; // For web or when ML Kit fails
  
  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    _initServices();
  }
  
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      // Handle permission denied
      print('Camera permission denied');
    }
  }
  
  void _initServices() {
    // Initialize face detector
    faceDetectorService = FaceDetectorService();
    
    // Initialize lighting analyzer
    lightingAnalyzer = LightingAnalyzer();
    
    // Initialize camera with front camera if available
    final frontCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras.first,
    );
    
    cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    
    cameraController!.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      
      // Start the image stream
      cameraController!.startImageStream(_processImage);
    }).catchError((e) {
      print('Error initializing camera: $e');
    });
  }
  
  void _processImage(CameraImage image) async {
    if (mounted) {
      try {
        // Process lighting
        final lighting = await lightingAnalyzer!.analyzeLighting(image);
        
        // Process face detection using ML Kit
        final faces = await faceDetectorService!.detectFaces(image, cameraController!.description);
        
        // If ML Kit cannot process the image (web, compatibility issues), use mock detection
        _useMockFace = kIsWeb || (faces == null || faces.isEmpty);
        
        // Process emotion when face is detected
        FacialCondition? condition;
        bool faceDetected = false;
        
        // Get lighting quality from analyzer for detection accuracy
        final double lightingQualityValue = lightingAnalyzer!.getLightingQuality(lighting);
        
        if (!_useMockFace && faces != null && faces.isNotEmpty) {
          // Real ML Kit detection worked
          condition = await faceDetectorService!.detectEmotion(faces.first, lightingQualityValue);
          faceDetected = true;
        } else {
          // Use mock face detection for web or fallback
          final mockFace = await faceDetectorService!.getSimulatedFace(image);
          if (mockFace != null) {
            condition = await faceDetectorService!.detectEmotionForMock(mockFace, lightingQualityValue);
            faceDetected = true;
            _mockFace = mockFace;
          }
        }
        
        // Consider lighting conditions in face detection
        // If lighting is too dark or too bright and face detection isn't reliable,
        // we can adjust our confidence or make recommendations
        if (lighting == "Too Dark" || lighting == "Too Bright") {
          // Lower confidence in detection under bad lighting
          if (condition != null && faceDetected) {
            // Get lighting quality factor (0-1)
            final double lightingQuality = lightingAnalyzer!.getLightingQuality(lighting);
            
            // Adjust confidence based on lighting quality
            // Worse lighting = lower confidence in detection
            final adjustedConfidence = condition.confidence * (0.3 + (0.7 * lightingQuality));
            
            // If confidence is too low in bad lighting, we might prioritize tiredness
            // as it's often more noticeable in poor lighting
            
            if (adjustedConfidence < 0.5 && lighting == "Too Dark") {
              condition = FacialCondition(
                emotion: EmotionType.tired,
                confidence: 0.6, // Moderate confidence in tiredness detection
                lightingQuality: lightingQualityValue,
              );
            } else {
              condition = FacialCondition(
                emotion: condition.emotion,
                confidence: adjustedConfidence,
                lightingQuality: lightingQualityValue,
              );
            }
          }
        }
        
        setState(() {
          _faces = faces;
          _faceDetected = faceDetected;
          _currentCondition = condition;
          _lightingCondition = lighting;
        });
      } catch (e) {
        print('Error processing image: $e');
        // Don't update state on error to preserve last good detection
      }
    }
  }
  
  @override
  void dispose() {
    cameraController?.dispose();
    faceDetectorService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Condition Detector'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Camera View
                CameraView(controller: cameraController!),
                
                // Face Overlay - for real ML Kit detection
                if (_faceDetected && !_useMockFace && _faces != null && _faces!.isNotEmpty)
                  FaceOverlay(
                    faces: _faces!,
                    previewSize: cameraController!.value.previewSize!,
                    screenSize: MediaQuery.of(context).size,
                  ),
                  
                // Mock Face Overlay - for web or fallback
                if (_faceDetected && _useMockFace && _mockFace != null)
                  CustomPaint(
                    painter: MockFaceOverlayPainter(
                      mockFace: _mockFace!,
                      previewSize: cameraController!.value.previewSize!,
                      screenSize: MediaQuery.of(context).size,
                    ),
                  ),
              ],
            ),
          ),
          
          // Condition Display
          Expanded(
            flex: 1,
            child: ConditionDisplay(
              facialCondition: _currentCondition,
              lightingCondition: _lightingCondition,
              faceDetected: _faceDetected,
            ),
          ),
        ],
      ),
    );
  }
}

// A painter for drawing mock faces
class MockFaceOverlayPainter extends CustomPainter {
  final MockFace mockFace;
  final Size previewSize;
  final Size screenSize;
  
  MockFaceOverlayPainter({
    required this.mockFace,
    required this.previewSize,
    required this.screenSize,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Paint settings for the face boundaries
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.orange; // Different color to indicate mock detection
    
    // Paint settings for the facial landmarks
    final Paint landmarkPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.yellow
      ..strokeWidth = 3.0;
    
    // Calculate scale factors to map the face coordinates
    final double scaleX = size.width / previewSize.height;
    final double scaleY = size.height / previewSize.width;
    
    // Draw face boundary
    final double left = mockFace.boundingBox.left * scaleX;
    final double top = mockFace.boundingBox.top * scaleY;
    final double right = mockFace.boundingBox.right * scaleX;
    final double bottom = mockFace.boundingBox.bottom * scaleY;
    
    // Draw the face rectangle
    canvas.drawRect(
      Rect.fromLTRB(left, top, right, bottom),
      paint,
    );
    
    // Draw key facial points
    if (mockFace.leftEyeOpenProbability != null) {
      // Draw a circle for left eye
      canvas.drawCircle(
        Offset(
          (left + right) / 4, // Approximate left eye position
          (top + top + bottom) / 3,
        ),
        5.0,
        landmarkPaint,
      );
      
      // Draw a circle for right eye
      canvas.drawCircle(
        Offset(
          (left + right) * 3 / 4, // Approximate right eye position
          (top + top + bottom) / 3,
        ),
        5.0,
        landmarkPaint,
      );
      
      // Draw a circle for nose
      canvas.drawCircle(
        Offset(
          (left + right) / 2, // Approximate nose position
          (top + bottom) / 2,
        ),
        5.0,
        landmarkPaint,
      );
      
      // Draw a circle for mouth
      canvas.drawCircle(
        Offset(
          (left + right) / 2, // Approximate mouth position
          (top + bottom) * 2 / 3,
        ),
        5.0,
        landmarkPaint,
      );
    }
    
    // Write the confidence score using smiling probability
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: 'Web Demo${kIsWeb ? " (Web Browser)" : " (Fallback Mode)"}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          backgroundColor: Colors.black54,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset(left, top - 20));
  }
  
  @override
  bool shouldRepaint(MockFaceOverlayPainter oldDelegate) {
    return oldDelegate.mockFace != mockFace;
  }
}