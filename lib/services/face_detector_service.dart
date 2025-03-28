import 'package:camera/camera.dart';
import 'package:face_condition_detector/lighting_analyzer.dart' as detector_lighting;
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/image_converter.dart';
import '../models/facial_condition.dart';
import 'tensorflow_service.dart';
import 'dart:math';

// Create a simple class to represent a mock face
class MockFace {
  final Rect boundingBox;
  final double? smilingProbability;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  
  MockFace({
    required this.boundingBox,
    this.smilingProbability,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
  });
}

class FaceDetectorService {
  final FaceDetector _faceDetector;
  final Random _random = Random();
  final TensorFlowService _tensorFlowService = TensorFlowService();
  bool _isTensorFlowInitialized = false;
  
  FaceDetectorService()
      : _faceDetector = GoogleMlKit.vision.faceDetector(
          FaceDetectorOptions(
            enableClassification: true, // For smile detection
            enableContours: true,       // For facial contours
            enableLandmarks: true,      // For facial landmarks 
          ),
        ) {
    _initTensorFlow();
  }

  get faces => null;
  
  Future<void> _initTensorFlow() async {
    try {
      await _tensorFlowService.initialize();
      _isTensorFlowInitialized = true;
      print('TensorFlow service initialized');
    } catch (e) {
      print('Error initializing TensorFlow service: $e');
    }
  }
  
  // This detects faces using ML Kit with a fallback for web
  Future<List<Face>?> detectFaces(CameraImage image, CameraDescription camera) async {
    try {
      // Try to convert camera image to input image for ML Kit processing
      final inputImage = ImageConverter.convertCameraImage(image, camera);
      
      // If we have a valid inputImage (on native mobile platforms), process it
      if (inputImage != null) {
        try {
          final faces = await _faceDetector.processImage(inputImage);
          return faces;
        } catch (e) {
          print('Error processing image: $e');
          // Fall back to simulated detection
        }
      }
      
      // For web demo or if camera image processing fails, return empty list
      // We can't create Face objects directly as they're from the ML Kit package
      print('Using simulated face detection for demo');
      return [];
    } catch (e) {
      print('Error in face detection service: $e');
      return [];
    }
  }
  
  // Create a simulated face detection for web/demo purposes
  Future<MockFace?> getSimulatedFace(CameraImage image) async {
    // For demo, randomly decide if a face is detected (80% chance)
    if (_random.nextDouble() < 0.8) {
      // Create a simulated rectangle in the center of the image
      final centerX = image.width / 2;
      final centerY = image.height / 2;
      final width = image.width / 3;
      final height = image.height / 3;
      
      final mockRect = Rect.fromLTRB(
        centerX - width / 2, 
        centerY - height / 2,
        centerX + width / 2, 
        centerY + height / 2
      );
      
      return MockFace(
        boundingBox: mockRect,
        smilingProbability: _random.nextDouble(),
        leftEyeOpenProbability: _random.nextDouble(),
        rightEyeOpenProbability: _random.nextDouble(),
      );
    }
    return null;
  }
  
  // Detect emotion using TensorFlow for real faces
  Future<FacialCondition?> detectEmotion(Face face, [double lightingQuality = 0.9]) async {
    try {
      // If TensorFlow is available, use it for advanced emotion detection
      if (_isTensorFlowInitialized) {
        // We could pass the face crop to TensorFlow if we extracted it
        // For now, we'll use the smiling probability from face detection
        
        // Check if smiling (available in face detection)
        final bool isSmiling = face.smilingProbability != null && face.smilingProbability! > 0.7;
        
        if (isSmiling) {
          return FacialCondition(
            emotion: EmotionType.happy,
            confidence: face.smilingProbability ?? 0.8,
            lightingQuality: lightingQuality,
            stress: 0.0, emotionConfidence: 0.0, faceId: 0, tiredness: 0.0, 
           lightingCondition: detector_lighting.LightingCondition.normal, timestamp: DateTime.now(),
          );
        }
        
        // Get the dominant emotion from our tensorflow service
        // This uses the implemented mock data when TensorFlow Lite can't process in real-time
        final EmotionType dominantEmotion = _tensorFlowService.getDominantEmotion();
        final confidence = _tensorFlowService.emotionData[dominantEmotion] ?? 0.7;
        
        // Use eye openness to help detect tiredness
        // Lower eye openness suggests more tiredness
        final leftEyeOpen = face.leftEyeOpenProbability ?? 0.8;
        final rightEyeOpen = face.rightEyeOpenProbability ?? 0.8;
        final eyeOpenness = (leftEyeOpen + rightEyeOpen) / 2.0;
        
        // If eyes are noticeably closed (below 0.3), prioritize tiredness
        if (eyeOpenness < 0.3 && confidence < 0.8) {
          return FacialCondition(
            emotion: EmotionType.tired,
            confidence: 0.7 + (0.3 - eyeOpenness), // More closed = higher confidence
            lightingQuality: lightingQuality,
            stress: 0.0, emotionConfidence: 0.0, faceId: 0, tiredness: 0.0, 
           lightingCondition: detector_lighting.LightingCondition.normal, timestamp: DateTime.now(),
          );
        }
        
        return FacialCondition(
          emotion: dominantEmotion,
          confidence: confidence,
          lightingQuality: lightingQuality,
          stress: 0.0, emotionConfidence: 0.0, faceId: 0, tiredness: 0.0, 
           lightingCondition: detector_lighting.LightingCondition.normal, timestamp: DateTime.now(),
        );
      } else {
        // Fallback to basic detection
        return _fallbackEmotionDetection(lightingQuality);
      }
    } catch (e) {
      print('Error detecting emotion: $e');
      return _fallbackEmotionDetection(lightingQuality);
    }
  }
  
  // Fallback emotion detection
  FacialCondition _fallbackEmotionDetection([double lightingQuality = 0.9]) {
    // For web demo, randomly assign emotions with some weighting
    final emotions = [
      EmotionType.neutral,
      EmotionType.sad,
      EmotionType.angry,
      EmotionType.surprised,
      EmotionType.fearful,
      EmotionType.disgusted,
      EmotionType.tired,
      EmotionType.stressed,
    ];
    
    // Randomly select an emotion
    final randomIndex = _random.nextInt(emotions.length);
    final randomEmotion = emotions[randomIndex];
    
    // Generate a random confidence level (0.6 - 0.95)
    final confidence = 0.6 + (_random.nextDouble() * 0.35);
    
    return FacialCondition(
      emotion: randomEmotion,
      confidence: confidence,
      lightingQuality: lightingQuality,
      stress: 0.0, emotionConfidence: 0.0, faceId: 0, tiredness: 0.0, 
           lightingCondition: detector_lighting.LightingCondition.normal, timestamp: DateTime.now(),
    );
  }
  
  // Simulate emotion detection for MockFace (used in web)
  Future<FacialCondition?> detectEmotionForMock(MockFace face, [double lightingQuality = 0.9]) async {
    try {
      // Similar logic as the real detection
      final bool isSmiling = face.smilingProbability != null && face.smilingProbability! > 0.7;
      
      if (isSmiling) {
        return FacialCondition(
          emotion: EmotionType.happy,
          confidence: face.smilingProbability ?? 0.8,
          lightingQuality: lightingQuality,
          stress: 0.0, emotionConfidence: 0.0, faceId: 0, tiredness: 0.0, 
           lightingCondition: detector_lighting.LightingCondition.normal, timestamp: DateTime.now(),
        );
      }
      
      if (_isTensorFlowInitialized) {
        // Get the dominant emotion from our tensorflow service
        final EmotionType dominantEmotion = _tensorFlowService.getDominantEmotion();
        final confidence = _tensorFlowService.emotionData[dominantEmotion] ?? 0.7;
        
        // Also use eye openness for tiredness detection in mock faces
        final leftEyeOpen = face.leftEyeOpenProbability ?? 0.8;
        final rightEyeOpen = face.rightEyeOpenProbability ?? 0.8;
        final eyeOpenness = (leftEyeOpen + rightEyeOpen) / 2.0;
        
        // If eyes are noticeably closed (below 0.3), prioritize tiredness
        if (eyeOpenness < 0.3 && confidence < 0.8) {
          return FacialCondition(
            emotion: EmotionType.tired,
            confidence: 0.7 + (0.3 - eyeOpenness), // More closed = higher confidence
            lightingQuality: lightingQuality, stress: 0.0, emotionConfidence: 0.0, faceId: 0, tiredness: 0.0, 
           lightingCondition: detector_lighting.LightingCondition.normal, timestamp: DateTime.now(),
          );
        }
        
        return FacialCondition(
          emotion: dominantEmotion,
          confidence: confidence,
          lightingQuality: lightingQuality,stress: 0.0, emotionConfidence: 0.0, faceId: 0, tiredness: 0.0, 
           lightingCondition: detector_lighting.LightingCondition.normal, timestamp: DateTime.now(),
        );
      } else {
        return _fallbackEmotionDetection(lightingQuality);
      }
    } catch (e) {
      print('Error detecting emotion for mock face: $e');
      return _fallbackEmotionDetection(lightingQuality);
    }
  }
  
  void dispose() {
    _faceDetector.close();
    _tensorFlowService.dispose();
  }

  processImage(CameraImage image, CameraDescription cameraDescription) {}

  initialize() {}
}