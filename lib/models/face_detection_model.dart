import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../models/facial_condition.dart';

class FaceDetectionModel extends ChangeNotifier {
  Face? _face;
  FacialCondition? _facialCondition;
  bool _isProcessing = false;
  String _lightingCondition = "Normal";
  double _lightingIntensity = 0.0; // Range: -1.0 (too dim) to 1.0 (too bright)
  bool _faceDetected = false;

  // Getters
  Face? get face => _face;
  FacialCondition? get facialCondition => _facialCondition;
  bool get isProcessing => _isProcessing;
  String get lightingCondition => _lightingCondition;
  double get lightingIntensity => _lightingIntensity;
  bool get faceDetected => _faceDetected;

  // Update face detection results
  void updateFace(Face? face) {
    _face = face;
    _faceDetected = face != null;
    notifyListeners();
  }

  // Update facial condition analysis
  void updateFacialCondition(FacialCondition condition) {
    _facialCondition = condition;
    notifyListeners();
  }

  // Update lighting condition
  void updateLightingCondition(String condition, double intensity) {
    _lightingCondition = condition;
    _lightingIntensity = intensity;
    notifyListeners();
  }

  // Set processing state
  void setProcessing(bool isProcessing) {
    _isProcessing = isProcessing;
    notifyListeners();
  }

  // Reset all data
  void reset() {
    _face = null;
    _facialCondition = null;
    _isProcessing = false;
    _lightingCondition = "Normal";
    _lightingIntensity = 0.0;
    _faceDetected = false;
    notifyListeners();
  }
}
