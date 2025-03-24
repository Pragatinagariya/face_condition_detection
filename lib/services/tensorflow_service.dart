import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:math' as math;

import '../models/facial_condition.dart';
import '../utils/image_converter.dart';
import '../utils/lighting_analyzer.dart';

// Conditional import for tflite_flutter
// We don't import it directly because it causes issues on web
// Instead we'll handle it gracefully

class TensorFlowService {
  dynamic _emotionModel; // Using dynamic to avoid direct typing to Interpreter
  bool _isInitialized = false;
  
  // Results of the latest processing
  Map<EmotionType, double> _emotionData = {};
  double _tirednessScore = 0.0;
  double _stressScore = 0.0;

  // Getters
  bool get isInitialized => _isInitialized;
  Map<EmotionType, double> get emotionData => _emotionData;
  double get tirednessScore => _tirednessScore;
  double get stressScore => _stressScore;

  Future<void> initialize() async {
    // We'll use a web-friendly approach that skips TFLite
    _isInitialized = true;
    
    // We could conditionally load the TFLite model for non-web platforms
    // But for simplicity, we'll use the same approach everywhere initially
    print('TensorFlow service initialized with web-friendly approach');
    return;
  }

  Future<void> processImage(CameraImage image, Face face, CameraDescription camera) async {
    if (!_isInitialized) {
      print('TensorFlow service not initialized');
      return;
    }

    try {
      // Generate simulated predictions for emotions
      _simulatePredictions();

      // Calculate tiredness and stress based on face landmarks and emotion
      _calculateTirednessAndStress(face);
    } catch (e) {
      print('Error processing image in TensorFlow service: $e');
      // Reset results
      _emotionData = {
        for (var emotion in EmotionType.values) emotion: 0.0
      };
      _emotionData[EmotionType.neutral] = 1.0;
      _tirednessScore = 0.0;
      _stressScore = 0.0;
    }
  }

  // For simulating emotion predictions
  void _simulatePredictions() {
    // Reset emotion data
    _emotionData = {
      for (var emotion in EmotionType.values) emotion: 0.0
    };
    
    // Assign values based on commonly observed patterns
    // This is a simplified simulation - a real model would be more accurate
    _emotionData[EmotionType.happy] = 0.3;
    _emotionData[EmotionType.neutral] = 0.4;
    _emotionData[EmotionType.tired] = 0.15;
    _emotionData[EmotionType.stressed] = 0.05;
    _emotionData[EmotionType.sad] = 0.05;
    _emotionData[EmotionType.angry] = 0.02;
    _emotionData[EmotionType.surprised] = 0.02;
    _emotionData[EmotionType.fearful] = 0.01;
    _emotionData[EmotionType.disgusted] = 0.0;
    
    // Add a bit of randomness to make it more realistic
    final random = math.Random();
    bool hasRandomEmphasis = random.nextBool();
    
    if (hasRandomEmphasis) {
      // Randomly emphasize one emotion
      final emotions = EmotionType.values.toList();
      final randomEmotion = emotions[random.nextInt(emotions.length)];
      
      // Boost this emotion
      _emotionData[randomEmotion] = _emotionData[randomEmotion]! + random.nextDouble() * 0.3;
      
      // Normalize to sum to 1.0
      double total = _emotionData.values.reduce((sum, value) => sum + value);
      for (var emotion in EmotionType.values) {
        _emotionData[emotion] = _emotionData[emotion]! / total;
      }
    }
  }

  void _calculateTirednessAndStress(Face face) {
    // Calculate tiredness based on eye openness and other factors
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0.8;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0.8;
    
    // Lower eye openness suggests more tiredness
    _tirednessScore = 1.0 - ((leftEyeOpen + rightEyeOpen) / 2.0);
    
    // Adjust based on emotion
    if (_emotionData[EmotionType.tired] != null && _emotionData[EmotionType.tired]! > 0.3) {
      _tirednessScore = math.max(_tirednessScore, _emotionData[EmotionType.tired]!);
    }
    
    // Calculate stress based on facial expressions and emotions
    const stressEmotions = [EmotionType.angry, EmotionType.fearful, EmotionType.stressed];
    double stressFromEmotion = 0.0;
    
    for (var emotion in stressEmotions) {
      stressFromEmotion += _emotionData[emotion] ?? 0.0;
    }
    
    _stressScore = math.min(1.0, stressFromEmotion);
  }

  // Analyze lighting conditions from the camera image
  LightingCondition getLightingCondition(CameraImage image) {
    return LightingAnalyzer.analyzeLighting(image);
  }

  void dispose() async {
    _isInitialized = false;
    _emotionData = {};
    _tirednessScore = 0.0;
    _stressScore = 0.0;
  }
}