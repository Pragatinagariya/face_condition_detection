import 'package:face_condition_detector/lighting_analyzer.dart';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'facial_condition.dart';

class FaceDetectionModel extends ChangeNotifier {
  bool _faceDetected = false;
  bool _isProcessing = false;
  FacialCondition? _facialCondition;

  // Getters
  bool get faceDetected => _faceDetected;
  bool get isProcessing => _isProcessing;
  FacialCondition? get facialCondition => _facialCondition;

  // Setters
  set faceDetected(bool value) {
    if (_faceDetected != value) {
      _faceDetected = value;
      notifyListeners();
    }
  }

  set isProcessing(bool value) {
    if (_isProcessing != value) {
      _isProcessing = value;
      notifyListeners();
    }
  }

  void updateFacialCondition({
    required Face faceData,
    required Map<EmotionType, double> emotionData,
    required double tiredness,
    required double stress,
    required LightingCondition lightingCondition,
  }) {
    // Find the dominant emotion
    EmotionType dominantEmotion = EmotionType.neutral;
    double maxScore = 0;
    
    emotionData.forEach((emotion, score) {
      if (score > maxScore) {
        maxScore = score;
        dominantEmotion = emotion;
      }
    });

    // Create a new facial condition object
    _facialCondition = FacialCondition(
      faceId: faceData.trackingId ?? 0,
      emotion: dominantEmotion,
      emotionConfidence: maxScore,
      tiredness: tiredness,
      stress: stress,
      lightingCondition: lightingCondition,
      timestamp: DateTime.now(), confidence: 0.0,
    );

    notifyListeners();
  }

  void reset() {
    _faceDetected = false;
    _isProcessing = false;
    _facialCondition = null;
    notifyListeners();
  }
}