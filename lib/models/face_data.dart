import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../emotion_analyzer.dart';
import '../lighting_analyzer.dart';

class FaceData {
  final Rect boundingBox;
  final EmotionType emotionType;
  final double emotionConfidence;
  final LightingCondition lightingCondition;
  final double isSmilingProbability;
  final double leftEyeOpenProbability;
  final double rightEyeOpenProbability;

  FaceData({
    required this.boundingBox,
    required this.emotionType,
    required this.emotionConfidence,
    required this.lightingCondition,
    required this.isSmilingProbability,
    required this.leftEyeOpenProbability,
    required this.rightEyeOpenProbability,
  });

  // Calculate tiredness score based on eye openness and smiling probability
  double get tirednessScore {
    // Average eye openness, lower means more tired
    double eyeOpenness = (leftEyeOpenProbability + rightEyeOpenProbability) / 2.0;
    
    // Smiling people tend to appear less tired
    double smileAdjustment = isSmilingProbability * 0.3;
    
    // If emotion is specifically tired, increase the score
    double emotionFactor = emotionType == EmotionType.tired ? 0.4 : 0.0;
    
    // A lower eye openness and low smile indicates tiredness
    return (1.0 - eyeOpenness) * 0.7 + emotionFactor - smileAdjustment;
  }

  // Calculate stress score based on emotion and other factors
  double get stressScore {
    double baseScore = 0.0;
    
    // If emotion is specifically stressed, increase the score
    if (emotionType == EmotionType.stressed) {
      baseScore += 0.6;
    } else if (emotionType == EmotionType.angry || 
               emotionType == EmotionType.fearful) {
      baseScore += 0.4;
    }
    
    // Smiling people tend to appear less stressed
    double smileAdjustment = isSmilingProbability * 0.3;
    
    return baseScore - smileAdjustment;
  }
  
  // Get emotion as user-friendly string
  String get emotionLabel {
    switch (emotionType) {
      case EmotionType.happy:
        return 'Happy';
      case EmotionType.sad:
        return 'Sad';
      case EmotionType.angry:
        return 'Angry';
      case EmotionType.surprised:
        return 'Surprised';
      case EmotionType.fearful:
        return 'Fearful';
      case EmotionType.disgusted:
        return 'Disgusted';
      case EmotionType.neutral:
        return 'Neutral';
      case EmotionType.tired:
        return 'Tired';
      case EmotionType.stressed:
        return 'Stressed';
      default:
        return 'Unknown';
    }
  }
  
  // Get lighting condition as user-friendly string
  String get lightingLabel {
    switch (lightingCondition) {
      case LightingCondition.tooDark:
        return 'Too Dark';
      case LightingCondition.normal:
        return 'Good Lighting';
      case LightingCondition.tooBright:
        return 'Too Bright';
      default:
        return 'Unknown';
    }
  }
  
  // Convert to string for debugging
  @override
  String toString() {
    return 'FaceData{emotion: $emotionLabel (${emotionConfidence.toStringAsFixed(2)}), '
           'lighting: $lightingLabel, '
           'smiling: ${isSmilingProbability.toStringAsFixed(2)}, '
           'tired: ${tirednessScore.toStringAsFixed(2)}, '
           'stressed: ${stressScore.toStringAsFixed(2)}}';
  }
}

class FaceDataModel extends ChangeNotifier {
  FaceData? _faceData;
  
  FaceData? get faceData => _faceData;
  
  void updateFaceData(FaceData newFaceData) {
    _faceData = newFaceData;
    notifyListeners();
  }
  
  void clearFaceData() {
    _faceData = null;
    notifyListeners();
  }
}
