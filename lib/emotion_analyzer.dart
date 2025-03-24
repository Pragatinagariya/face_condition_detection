import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

enum EmotionType {
  happy,
  sad,
  neutral,
  angry,
  surprised,
  fearful,
  disgusted,
  tired,
  stressed
}

class EmotionResult {
  final EmotionType dominantEmotion;
  final double confidence;
  final Map<EmotionType, double> allEmotions;

  EmotionResult({
    required this.dominantEmotion,
    required this.confidence,
    required this.allEmotions,
  });
}

class EmotionAnalyzer {
  Interpreter? _interpreter;
  List<String> _labels = [];
  
  // Private constructor for factory pattern
  EmotionAnalyzer._();
  
  // Factory constructor
  static Future<EmotionAnalyzer> create() async {
    final analyzer = EmotionAnalyzer._();
    await analyzer._initialize();
    return analyzer;
  }
  
  Future<void> _initialize() async {
    try {
      // Load model from assets
      final interpreterOptions = InterpreterOptions();
      
      // Load model
      _interpreter = await Interpreter.fromAsset(
        'assets/models/emotion_model.tflite',
        options: interpreterOptions,
      );
      
      // Define labels for emotion classification
      // The order should match the model's output tensor
      _labels = [
        'angry', 'disgusted', 'fearful', 'happy', 
        'neutral', 'sad', 'surprised', 'tired', 'stressed'
      ];
    } catch (e) {
      print('Error initializing emotion analyzer: $e');
      // Fallback to simpler method if model loading fails
      _interpreter = null;
    }
  }
  
  Future<EmotionResult> analyzeEmotion(img.Image faceImage) async {
    if (_interpreter == null) {
      // Fallback to a simple color-based analysis if model is not available
      return _fallbackEmotionAnalysis(faceImage);
    }
    
    try {
      // Convert the image to the format expected by the model
      // Preprocess the image (resize, normalize pixel values, etc.)
      img.Image resizedImage = img.copyResize(faceImage, width: 48, height: 48);
      
      // Convert to grayscale if needed
      img.Image grayImage = img.grayscale(resizedImage);
      
      // Create input tensor
      var inputShape = _interpreter!.getInputTensor(0).shape;
      var outputShape = _interpreter!.getOutputTensor(0).shape;
      
      // Prepare input data - normalize pixel values to [0,1]
      var inputData = Float32List(1 * 48 * 48 * 1); // Assuming grayscale input
      int pixelIndex = 0;
      for (int y = 0; y < 48; y++) {
        for (int x = 0; x < 48; x++) {
          var pixel = grayImage.getPixel(x, y);
          // Normalize from [0,255] to [0,1]
          inputData[pixelIndex++] = img.getRed(pixel) / 255.0;
        }
      }
      
      var inputTensor = [inputData];
      
      // Prepare output tensor
      var outputTensor = List<dynamic>.filled(
        1, 
        List<double>.filled(outputShape[1], 0.0)
      );
      
      // Run inference
      _interpreter!.run(inputTensor, outputTensor);
      
      // Process results
      List<double> emotionScores = List<double>.from(outputTensor[0]);
      
      // Map scores to emotions
      Map<EmotionType, double> emotions = {};
      for (int i = 0; i < _labels.length; i++) {
        EmotionType emotion = _labelToEmotionType(_labels[i]);
        emotions[emotion] = emotionScores[i];
      }
      
      // Find dominant emotion
      EmotionType dominantEmotion = emotions.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      double confidence = emotions[dominantEmotion]!;
      
      return EmotionResult(
        dominantEmotion: dominantEmotion,
        confidence: confidence,
        allEmotions: emotions,
      );
    } catch (e) {
      print('Error during emotion analysis: $e');
      return _fallbackEmotionAnalysis(faceImage);
    }
  }
  
  EmotionType _labelToEmotionType(String label) {
    switch (label) {
      case 'happy': return EmotionType.happy;
      case 'sad': return EmotionType.sad;
      case 'neutral': return EmotionType.neutral;
      case 'angry': return EmotionType.angry;
      case 'surprised': return EmotionType.surprised;
      case 'fearful': return EmotionType.fearful;
      case 'disgusted': return EmotionType.disgusted;
      case 'tired': return EmotionType.tired;
      case 'stressed': return EmotionType.stressed;
      default: return EmotionType.neutral;
    }
  }
  
  // Fallback method for emotion analysis
  EmotionResult _fallbackEmotionAnalysis(img.Image faceImage) {
    // Calculate average color values
    int totalR = 0, totalG = 0, totalB = 0;
    int pixelCount = 0;
    
    for (int y = 0; y < faceImage.height; y++) {
      for (int x = 0; x < faceImage.width; x++) {
        final pixel = faceImage.getPixel(x, y);
        totalR += img.getRed(pixel);
        totalG += img.getGreen(pixel);
        totalB += img.getBlue(pixel);
        pixelCount++;
      }
    }
    
    double avgR = totalR / pixelCount;
    double avgG = totalG / pixelCount;
    double avgB = totalB / pixelCount;
    
    // Simple heuristic for emotion based on color values
    Map<EmotionType, double> emotions = {
      EmotionType.happy: 0.0,
      EmotionType.sad: 0.0,
      EmotionType.neutral: 0.3, // Default base value
      EmotionType.angry: 0.0,
      EmotionType.surprised: 0.0,
      EmotionType.fearful: 0.0,
      EmotionType.disgusted: 0.0,
      EmotionType.tired: 0.0,
      EmotionType.stressed: 0.0,
    };
    
    // Brightness can indicate overall mood
    double brightness = (avgR + avgG + avgB) / (3 * 255);
    
    // Red dominance might indicate anger or stress
    if (avgR > avgG * 1.2 && avgR > avgB * 1.2) {
      emotions[EmotionType.angry] = 0.4 + (avgR / 255) * 0.3;
      emotions[EmotionType.stressed] = 0.3 + (avgR / 255) * 0.3;
    }
    
    // High green with good brightness might indicate happiness
    if (avgG > avgR && avgG > avgB && brightness > 0.5) {
      emotions[EmotionType.happy] = 0.5 + (avgG / 255) * 0.3;
    }
    
    // Low overall brightness might indicate sadness or tiredness
    if (brightness < 0.4) {
      emotions[EmotionType.sad] = 0.4 + (1 - brightness) * 0.4;
      emotions[EmotionType.tired] = 0.3 + (1 - brightness) * 0.5;
    }
    
    // High brightness might indicate surprise
    if (brightness > 0.7) {
      emotions[EmotionType.surprised] = 0.4 + brightness * 0.3;
    }
    
    // Find dominant emotion
    EmotionType dominantEmotion = emotions.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    double confidence = emotions[dominantEmotion]!;
    
    return EmotionResult(
      dominantEmotion: dominantEmotion,
      confidence: confidence,
      allEmotions: emotions,
    );
  }
  
  void dispose() {
    _interpreter?.close();
  }
}
