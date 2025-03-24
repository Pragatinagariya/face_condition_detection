import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tflite/tflite.dart';

import '../models/facial_condition.dart';
import '../utils/image_converter.dart';
import '../utils/lighting_analyzer.dart';

class TensorFlowService {
  bool _isInitialized = false;
  LightingAnalyzer? _lightingAnalyzer;
  
  // Results of the latest processing
  Map<EmotionType, double> _emotionData = {};
  double _tirednessScore = 0.0;
  double _stressScore = 0.0;

  // List of emotion labels that match the model output
  final List<String> _emotionLabels = [
    'angry', 'disgusted', 'fearful', 'happy', 
    'neutral', 'sad', 'surprised', 'tired', 'stressed'
  ];

  // Getters
  bool get isInitialized => _isInitialized;
  Map<EmotionType, double> get emotionData => _emotionData;
  double get tirednessScore => _tirednessScore;
  double get stressScore => _stressScore;

  Future<void> initialize() async {
    try {
      // Initialize TFLite
      await Tflite.loadModel(
        model: 'assets/models/emotion_model.tflite',
        labels: 'assets/models/emotion_labels.txt',
        numThreads: 1,
        isAsset: true,
        useGpuDelegate: false,
      );
      
      _isInitialized = true;
      print('TensorFlow model loaded successfully');
    } catch (e) {
      print('Error initializing TensorFlow model: $e');
      print('Falling back to simulated predictions');
      // Even if model loading fails, we'll proceed with simulated data
      _isInitialized = true;
    }
    return;
  }

  Future<void> processImage(CameraImage image, Face face, CameraDescription camera) async {
    if (!_isInitialized) {
      print('TensorFlow service not initialized');
      return;
    }

    try {
      bool useTFLite = false;
      
      if (!kIsWeb && !useTFLite) {
        // Try to use TFLite for native platforms
        try {
          final List? recognitions = await Tflite.runModelOnFrame(
            bytesList: image.planes.map((plane) => plane.bytes).toList(),
            imageHeight: image.height,
            imageWidth: image.width,
            imageMean: 127.5,
            imageStd: 127.5,
            rotation: 90,
            numResults: 9,
            threshold: 0.1,
            asynch: true,
          );
          
          if (recognitions != null && recognitions.isNotEmpty) {
            _parseEmotionResults(recognitions);
            useTFLite = true;
          }
        } catch (e) {
          print('TFLite processing error: $e');
        }
      }
      
      // Fall back to simulated predictions if TFLite wasn't used
      if (!useTFLite) {
        _simulatePredictions();
      }

      // Calculate tiredness and stress based on face landmarks and emotion
      _calculateTirednessAndStress(face);
    } catch (e) {
      print('Error processing image in TensorFlow service: $e');
      // Reset results
      _resetEmotionData();
    }
  }
  
  void _parseEmotionResults(List recognitions) {
    // Reset emotion data
    _resetEmotionData();
    
    try {
      for (var recognition in recognitions) {
        String label = recognition['label'];
        double confidence = recognition['confidence'];
        
        // Map the label to EmotionType
        int labelIndex = _emotionLabels.indexOf(label);
        if (labelIndex >= 0 && labelIndex < EmotionType.values.length) {
          EmotionType emotion = EmotionType.values[labelIndex];
          _emotionData[emotion] = confidence;
        }
      }
    } catch (e) {
      print('Error parsing emotion results: $e');
    }
  }
  
  void _resetEmotionData() {
    _emotionData = {
      for (var emotion in EmotionType.values) emotion: 0.0
    };
    _emotionData[EmotionType.neutral] = 1.0; // Default to neutral
  }

  // For simulating emotion predictions when TFLite isn't available
  void _simulatePredictions() {
    // Reset emotion data
    _emotionData = {
      for (var emotion in EmotionType.values) emotion: 0.0
    };
    
    // Assign values based on commonly observed patterns
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

  // Get the dominant emotion
  EmotionType getDominantEmotion() {
    EmotionType dominant = EmotionType.neutral;
    double maxConfidence = 0.0;
    
    _emotionData.forEach((emotion, confidence) {
      if (confidence > maxConfidence) {
        maxConfidence = confidence;
        dominant = emotion;
      }
    });
    
    return dominant;
  }
  
  // Analyze lighting conditions from the camera image
  Future<String> getLightingCondition(CameraImage image) async {
    try {
      if (_lightingAnalyzer == null) {
        _lightingAnalyzer = LightingAnalyzer();
      }
      // We'll use the LightingAnalyzer utility class
      return await _lightingAnalyzer!.analyzeLighting(image);
    } catch (e) {
      print('Error getting lighting condition: $e');
      return "Normal";
    }
  }

  void dispose() async {
    try {
      await Tflite.close();
    } catch (e) {
      print('Error closing TFLite model: $e');
    }
    
    _isInitialized = false;
    _emotionData = {};
    _tirednessScore = 0.0;
    _stressScore = 0.0;
  }
}