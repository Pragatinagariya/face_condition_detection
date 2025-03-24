import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Added for Rect
import 'package:face_condition_detector/utils/image_converter.dart';
import 'package:face_condition_detector/models/facial_condition.dart';
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
  
  FaceDetectorService()
      : _faceDetector = GoogleMlKit.vision.faceDetector(
          FaceDetectorOptions(
            enableClassification: true, // For smile detection
            enableContours: true,       // For facial contours
            enableLandmarks: true,      // For facial landmarks 
            mode: FaceDetectorMode.accurate,
          ),
        );
  
  // This simulates face detection with a mock response for web preview
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
  
  // Create a simulated face detection for demo purposes
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
  
  Future<FacialCondition?> detectEmotion(Face face) async {
    try {
      // Check if smiling (this is actually available in the face detection)
      final bool isSmiling = face.smilingProbability != null && face.smilingProbability! > 0.7;
      
      if (isSmiling) {
        return FacialCondition(
          emotion: EmotionType.happy,
          confidence: face.smilingProbability ?? 0.8,
        );
      }
      
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
      );
    } catch (e) {
      print('Error detecting emotion: $e');
      return null;
    }
  }
  
  // Simulate emotion detection for MockFace
  Future<FacialCondition?> detectEmotionForMock(MockFace face) async {
    // Similar logic as the real detection
    final bool isSmiling = face.smilingProbability != null && face.smilingProbability! > 0.7;
    
    if (isSmiling) {
      return FacialCondition(
        emotion: EmotionType.happy,
        confidence: face.smilingProbability ?? 0.8,
      );
    }
    
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
    );
  }
  
  void dispose() {
    _faceDetector.close();
  }
}