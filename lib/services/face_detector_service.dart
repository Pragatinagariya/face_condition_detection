import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:camera/camera.dart';
import '../utils/image_converter.dart';

class FaceDetectorService {
  late FaceDetector _faceDetector;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        enableClassification: true,
        enableContours: true,
        enableLandmarks: true,
        enableTracking: true,
        minFaceSize: 0.15,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    _isInitialized = true;
  }

  Future<List<Face>> detectFaces(CameraImage image, CameraDescription camera) async {
    if (!_isInitialized) {
      throw Exception('Face detector not initialized');
    }
    
    try {
      // Convert CameraImage to InputImage format required by ML Kit
      final inputImage = await ImageConverter.convertCameraImageToInputImage(
        image,
        camera,
      );
      
      if (inputImage == null) {
        return [];
      }
      
      // Process the image and detect faces
      final faces = await _faceDetector.processImage(inputImage);
      return faces;
    } catch (e) {
      print('Error detecting faces: $e');
      return [];
    }
  }

  // Method to determine if a face is clear enough for accurate analysis
  bool isFaceClear(Face face) {
    // Check if the face has sufficient area for reliable detection
    if (face.boundingBox.width < 100 || face.boundingBox.height < 100) {
      return false;
    }
    
    // Check if all required face contours are available
    if (!face.leftEyeOpenProbability.isPresent || 
        !face.rightEyeOpenProbability.isPresent) {
      return false;
    }
    
    return true;
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await _faceDetector.close();
      _isInitialized = false;
    }
  }
}
